RST2HTML = rst2html
XTX = crosstex
TEX2HTML = hevea -fix -O
TEX2PDF = rubber --pdf


.PHONY: all html resume cv

all: html resume cv


html: index.html

index.html: index.txt main.css google-analytics.html resume_updated.txt cv.xtx cv_pubs.html

%.html: %.txt main.css google-analytics.html
	$(RST2HTML) --stylesheet=main.css --initial-header-level=3 --date --source-link $< $@
	perl -i -pe 's#<meta\s+content="([^"]*)"\s+name="base"\s*/>#<base href="$$1" />#i;' \
	        -e  's#<head(.*?)>#<head$$1 profile="http://gmpg.org/xfn/11">#i;' \
	        -e  's#href="http://flickr.com/photos/ctl/"#rel="me" $$&#i;' \
	        -e  's#href="http://flickr.com/people/ctl/"#rel="me" $$&#i;' \
	        -e  's#href="http://www.linkedin.com/in/chrislesniewski"#rel="me" $$&#i;' \
	        -e  's#href="http://www.facebook.com/lesniewski"#rel="me" $$&#i;' \
	        -e  's#href="http://ctl.livejournal.com/profile"#rel="me" $$&#i;' \
	        -e  's#href="http://twitter.com/lesniewski"#rel="me" $$&#i;' \
		$@

resume: resume.pdf resume.html resume.txt

resume.pdf resume.html resume.txt resume_updated.txt: resume.pl
	perl resume.pl
	$(TEX2PDF) resume.tex



# Convert CV from CrossTeX into various formats.
cv: cv.pdf cv.bib

cv.pdf: cv.tex cv.bbl cv_updated.tex resume.cls
	$(TEX2PDF) $<

cv.bbl: cv.xtx
	$(XTX) --style cv_style --cite-by=number --break-lines \
	  --titlecase=as-is --sort=none \
	  --heading=category --no-field=howpublished \
	  --link Abstract --link HTML --link PDF --link PS $<
#         $(XTX) --style cv_style --cite-by=number --break-lines \
#           --titlecase=as-is --sort=none \
#           --heading=category --no-field=howpublished \
#           --link Abstract --link HTML --link PDF --link PS $<

cv_updated.tex: cv.xtx
	echo -n '\def\updated{' > $@
	sed -n '/^% *Updated */s///p' $< | tr -d '.\n' >> $@
	echo '}' >> $@

cv.bib: cv.xtx
	$(XTX) --xtx2bib --sort none --no-field=category \
	  --no-field abstract --no-field html --no-field pdf --no-field ps $<

# Incorporated into reseach.html.
cv_pubs.html: cv_pubs.tex cv_pubs.bbl
	$(TEX2HTML) $<
	perl -i -pe 'BEGIN{undef$$/} m:<DL CLASS="thebibliography">.*</DL>:s and $$_=$$&' $@

cv_pubs.bbl: cv_pubs.xtx
	$(XTX) --style cv_style --titlecase=default --sort=none $<
#         $(XTX) --style cv_style --blank-labels --break-lines \
#           --titlecase=as-is --sort=none \
#           --no-field=category \
#           --link Abstract --link HTML --link PDF --link PS $<

cv_pubs.xtx: cv.xtx
	ln -s $< $@
