#! /usr/bin/perl -w


# Read in the resume data.

$/ = "";

chomp(my $name = <DATA>);
chomp(my $homepage = <DATA>);
chomp(my $email = <DATA>);
chomp(my $updated = <DATA>);

chomp(my $lhdr = <DATA>);
chomp(my $rhdr = <DATA>);

my @sections = ();
while (<DATA>) {
  if (!/^  /) {
    # New section.
    s/^([^\n]*)\n  /  /s or die "syntax error at chunk $.";
    unshift @sections, [$1];
  }
  my @hdrs = ();
  until (/^     \*/) {
    s/^  ([^\n]*)\n//s or die "syntax error in chunk $.";
    push @hdrs, ( $1 ne '-' ? $1 : undef );
  }
  my @lis = ();
  until (/^\s*$/) {
    s/^     \* (.*?)\n(     \*|$)/$2/s or die "syntax error in chunk $.: '$_'";
    push @lis, $1;
  }
  push @{$sections[0]}, [[@hdrs], [@lis]];
}
@sections = reverse @sections;



# Output updated date.
open UPDATED, ">resume_updated.txt" or die "can't open resume_updated.txt: $!";
(my $short_updated = $updated) =~ s/^updated\s*(.*?)\.?\s*$/$1/i;
print UPDATED ".. |resume_updated| replace:: $short_updated\n";
close UPDATED or die "can't close resume_updated.txt: $!";


# Output text format.
my $COLUMNS = 72;

open TXT, ">resume.txt" or die "can't open resume.txt: $!";
select TXT;

sub centered {
  my $in = shift;
  return (" "x(($COLUMNS - length($in))/2)) . $in;
}
print centered($name), "\n";
print centered($homepage), "\n";
print centered($email), "\n";
print centered($updated), "\n\n";

sub stripfmt {
  local($_) = shift;
  s/\*\*(.*?)\*\*/$1/sg;
  s/\*(.*?)\*/$1/sg;
  s/\[(.*?)\]\(.*?\)/$1/sg;
  s/<(http:.*?)>/$1/sg;
  s/\s*-----*\s*//sg;
  $_;
}
my $txtlhdr = stripfmt $lhdr;
my $txtrhdr = stripfmt $rhdr;
my $rhdrwidth = 0;
for (split /\n/, $txtrhdr) { $rhdrwidth = length if $rhdrwidth < length; }
while ($txtlhdr || $txtrhdr) {
  $l = ($txtlhdr =~ s/^(.*?)(\n|$)//s) ? $1 : "";
  $r = ($txtrhdr =~ s/^(.*?)(\n|$)//s) ? $1 : "";
  print $l, (" " x ($COLUMNS - length($l) - $rhdrwidth)), $r, "\n";
}
print "\n";

foreach $section (@sections) {
  ($sechdr, @items) = @$section;
  print "$sechdr\n";
  for $item (@items) {
    ($hdrs, $lis) = @$item;
    ($what, $url, $where, $when) = @$hdrs;
    print "  $what\n"  if $what;
    print "  $where\n" if $where;
    print "  $when\n"  if $when;
    for (@$lis) {
      print "     * ", stripfmt($_), "\n";
    }
    print "\n";
  }
}


close TXT or die "can't close resume.txt: $!";






# Output HTML format.
open HTML, ">resume.html" or die "can't open resume.html: $!";
select HTML;

sub htmlfmt {
  local($_) = shift;
  s/&/&amp;/sg;
  s/</&lt;/sg;
  s/>/&gt;/sg;
  s/\*\*(.*?)\*\*/<b>$1<\/b>/sg;
  s/\*(.*?)\*/<i>$1<\/i>/sg;
  s/\[(.*?)\]\((.*?)\)/<a href=\"$2\">$1<\/a>/sg;
  s/&lt;(http:.*?)&gt;/<a href=\"$1\">$1<\/a>/sg;
  s/\s*-----*\s*//sg;
  $_;
}

print <<'EOT';
<html>
<head>
<title>Resume</title>
</head>
<body bgcolor=White text=Black>


<center>
<table align=center width=100%>
<tr>
<td align=left>
EOT

$htmllhdr = htmlfmt $lhdr;
$htmllhdr =~ s/^(.*)$/"    ".$1.(" "x($COLUMNS-length($1)-10))." <br>"/mge;
$htmlrhdr = htmlfmt $rhdr;
$htmlrhdr =~ s/^(.*)$/"    ".$1.(" "x($COLUMNS-length($1)-10))." <br>"/mge;

print "$htmllhdr\n";
print "</td>\n";
print "<td align=center>\n";
print "    <h3>$name</h3>\n";
print "    <tt><a href=\"$homepage\">$homepage</a></tt><br />\n";
print "    <tt>$email</tt>\n";
print "    <h5>$updated</h5>\n";
print "</td>\n";
print "<td align=right>\n";
print "$htmlrhdr\n";

print <<'EOT';
</td>
</tr>
</table>
</center>

<hr>


<table width=100%>

EOT

foreach $section (@sections) {
  ($sechdr, @items) = @$section;
  print "<tr><td colspan=4><font size=+1><b><i>$sechdr</i></b></font></td></tr>\n";
  for $item (@items) {
    ($hdrs, $lis) = @$item;
    if (@$hdrs) {
      ($what, $url, $where, $when) = (@$hdrs,"","");
      print "    <tr><td width=3%></td><td align=left ><b> ";
      print                          "<a href=\"$url\"> " if $url;
      print                          $what;
      print                          "</a>" if $url;
      print                          "</b></td>\n";
      print "        <td align=right><i>$where</i></td>\n" if $where;
      print "        <td></td>\n"                          if !$where;
      print "        <td align=right><b>$when</b></td>\n"  if $when;
      print "    </tr>\n";
    }
    print "    <tr><td></td><td colspan=3><ul>\n";
    for (@$lis) {
      print "        <li>", htmlfmt($_), "</li>\n";
    }
    print "    </ul></td></tr>\n";
  }
}

print <<'EOT';
</table>

</body>
</html>
EOT

close HTML or die "can't close resume.html: $!";










# Output LaTeX format.
open LATEX, ">resume.tex" or die "can't open resume.tex: $!";
select LATEX;

sub texfmt {
  local($_) = shift;
  s/"(.*?)"/``$1''/sg;
  s/&/\\&/sg;
  s/#/\\#/sg;
  s/</\$<\$/sg;
  s/>/\$>\$/sg;
  s/\*\*(.*?)\*\*/{\\bf $1}/sg;
  s/\*(.*?)\*/{\\it $1}/sg;
  s/\[(.*?)\]\((.*?)\)/\\href{$2}{$1}/sg;
  s/\$<\$(http:.*?)\$>\$/\\href{$1}{$1}/sg;
  s/\s*-----*\s*/\\newpage{}/sg;
  $_;
}




$texlhdr = texfmt $lhdr;
$texlhdr =~ s/^(.*)$/"    ".$1.(" "x($COLUMNS-length($1)-10))." \\\\"/mge;
$texrhdr = texfmt $rhdr;
$texrhdr =~ s/^(.*)$/"    ".$1.(" "x($COLUMNS-length($1)-10))." \\\\"/mge;


print <<'EOT';
\documentclass[10pt]{article}

\usepackage{color}
\definecolor{darkblue}{rgb}{0,0,0.5}
\usepackage[colorlinks=true,linkcolor=darkblue,urlcolor=darkblue]{hyperref}

\topmargin 0pt
\headheight 0pt
\headsep 0pt
\textheight 9in
\pagestyle{empty}
\parindent 0pt
\parskip \baselineskip
\topmargin 0in
\oddsidemargin 0in
\evensidemargin 0in
\textwidth 6.5in

\def\tbox#1{\begin{tabular}[t]{@{}l@{}}#1\end{tabular}}
\newbox\rtitle
\newenvironment{rlist}{\begin{list}{}{\setlength
 \labelwidth{0em}\setlength\leftmargin{\labelwidth}\addtolength
 \leftmargin{\labelsep}\itemsep 5pt plus 2pt minus 2pt
 \parsep 0pt plus 2pt minus 2pt
 %% Set the depth of the title to 0 in case more than one line.
 %% If the title takes more lines than the body, you lose.
 \def\sectiontitle##1{\vspace{6pt}
   \setbox\rtitle=\hbox{{\large\bf\tbox{##1}}}\dp\rtitle=0pt
   \item[\copy\rtitle]\ifdim\wd\rtitle>\labelwidth
   \leavevmode \\* \else \fi \vspace{-1em} }}}{\end{list}}

\def\employer#1{\par{\bf #1}\hfill}
\def\location#1{\textsl{#1\/}}
\def\dates#1{{\unskip\nobreak\penalty50\hskip2em
  \hbox{}\nobreak \hbox to 6em{\hfil\sf #1}\finalhyphendemerits=0 \\[-14pt]}}



\begin{document}


\hbox to \hsize{\tbox{
EOT
print "$texlhdr\n";
print "}\\hfil\\tbox{\n";
print "     {\\Large            $name} \\\\\n";
print "     {\\normalsize \\hfil \\href{$homepage}{$homepage}} \\\\\n";
print "     {\\normalsize \\hfil $email} \\\\\n";
print "     {\\footnotesize \\hfil $updated}\n";
print "}\\hfil\\tbox{\n";
print "$texrhdr\n";
print "}}\n\n\n";

print "\\vspace{10pt}\\hrule\\vspace{-10pt}\n\n";

print "\\begin{rlist}\n\n";



foreach $section (@sections) {
  ($sechdr, @items) = @$section;
  print "\\sectiontitle{$sechdr}\n";
  for $item (@items) {
    ($hdrs, $lis) = @$item;
    if (@$hdrs) {
      ($what, $url, $where, $when) = @$hdrs;
      $what = "\\href{$url}{$what}" if $url;
      print "  \\employer{$what}\n";
      print "  \\location{$where}\n" if $where;
      print "  \\dates{$when}\n"     if $when;
    }
    print "  \\begin{list}{\\labelitemi}{\\leftmargin=2em}\n";
    for (@$lis) {
      print "    \\item " . texfmt($_) . "\n";
    }
    print "  \\end{list}\n\n";
  }
}


print <<'EOT';

\end{rlist}
\end{document}
EOT




close LATEX or die "can't close resume.tex: $!";








# The markup below is ad-hoc and accumulated over the years.
# I recently (2010) changed it to include a small subset of Markdown.
__END__






Christopher T. Lesniewski-Laas

http://lesniewski.org/

ctl at mit dot edu 

Updated September 2010.


**Home Address**
1170 Arch Street
Berkeley, CA 94708

**Work Address**
1600 Amphitheatre Parkway
Mountain View, CA XXXXX




Experience
  Google
  http://www.google.com/
  Mountain View, CA
  2010 - Present
     * Developed and maintained search infrastructure systems.

  MIT CSAIL, Parallel and Distributed Operating Systems
  http://pdos.csail.mit.edu/
  Cambridge, MA
  2001 - 2010
     * Research focus: computer systems, especially security of
       large-scale decentralized Internet systems.
     * Thesis: [Whanau](http://pdos.csail.mit.edu/whanau/), a structured overlay routing protocol
       (DHT) which uses a social network to provide robustness
       against powerful pseudonym (Sybil) attacks.
       Advisor: [M. Frans Kaashoek](http://pdos.csail.mit.edu/~kaashoek/).
     * [UIA](http://pdos.csail.mit.edu/uia/) & [Eyo](http://pdos.csail.mit.edu/eyo/): decentralized routing, naming, & storage in a
       zero-configuration, secure, ad-hoc network.
     * [Alpaca](http://pdos.csail.mit.edu/alpaca/): secure and flexible PKI based on a higher-order
       logical framework.
     * Other work: distributed and dynamic compact routing for the
       Internet; coroutine-based asynchronous I/O programming framework;
       game theory, economics, mechanism design, and reputation in
       decentralized systems; distributed Web caching; RSA acceleration
       using a commodity GPU.
     * Master's thesis: [SSL Splitting and Barnraising: Cooperative
       Caching with Authenticity Guarantees](http://pdos.csail.mit.edu/papers/ssl-splitting-ctl-meng-abstract.html).
     * Instructor, 6.033 Computer Systems Engineering, 2003-2005.
     * Visiting scholar, Cambridge University Computer Lab, 2004.

  Permabit
  http://www.permabit.com/
  Cambridge, MA
  2001
     * Developed highly available, robust, secure, scalable data storage
       system based on commodity hardware.

  Microsoft Research
  http://research.microsoft.com/
  Redmond, WA
  2000
     * I-Campus *Secure Successor to the MIT Card* project:
       cryptographic protocol design.

  SensAble Technologies, Inc.
  http://www.sensable.com/
  Cambridge, MA
  1999
     * R&D: hardware and software development for the PHANToM haptic
       interface.

  MIT AI Lab, Mathematics and Computation
  http://www-swiss.ai.mit.edu/
  Cambridge, MA
  1998
     * Programmed randomly generated amorphous computers.
       Advisors: Hal Abelson, Gerry Sussman.

Education
  Massachusetts Institute of Technology
  http://mit.edu/
  Cambridge, MA
  1997 - 2010
     * Ph.D, Computer Science, September 2010.
     * M.Eng. and B.S. Electrical Engineering and Computer Science,
       June 2003.
     * B.S. Mathematics (Minor in Physics), June 2001.
     * Topics: algorithms, complexity, compilers, software design,
       modeling, cryptography, architecture, digital design, signal
       processing, probability, algebra, quantum+stat physics, general
       relativity, economics.

  Cohasset High School
  http://www.cohassetk12.org/
  Cohasset, MA
  1992 - 1997
     * Valedictorian, early graduation, Harvard Extension School,
       Center for Talented Youth (CTY).

Societies
     * MIT [Student Information Processing Board](http://stuff.mit.edu/sipb/) (Chair, 2003-2004)
     * [Eta Kappa Nu](http://hkn.mit.edu/) (editor of [UG6](http://hkn.mit.edu/ug_sel.php), 2000-2001)
     * [Phi Beta Kappa](http://www.pbk.org/)

Skills
     * Languages: Python, Haskell, C, C++ STL/Boost, Java, Perl,
       Javascript, LISP, Matlab, VHDL, Postscript, various assembly,
       SQL, XML, HTML, CSS, LaTeX, GLSL, LF, Intercal, French, Chinese
     * Network/system programming: TCP/IP, sockets, SSL/TLS, Kerberos,
       asynchronous, threads, load balancing, scheduling, consistency,
       kernels, compilers, JIT, virtualization, RDBMS, web apps, etc.
     * Unix development: Make, GCC, git, Subversion, svk, VIM, X11,
       test suites, Ubuntu, Solaris, etc.
     * Digital design: Xilinx FPGA development tools, use of
       oscilloscope, logic analyzer, datasheets, etc.
     * Hobbies: coding, cycling, photography, cooking, SCUBA, travel,
       hiking, karate, economics
       ---------------------------------------------------------------

Software systems developed at MIT
  Whanau
  http://pdos.csail.mit.edu/whanau/
  -
  2010
     * Designed and implemented a secure distributed hash table (DHT),
       a decentralized structured overlay network which can quickly
       look up the node responsible for a given key.  (Existing DHT
       applications include distributed databases, filesystems,
       caching, rendezvous, and streaming multicast.)
     * Novelty: Whanau uses an online social network to bootstrap a
       robust overlay network.  It is secure against powerful denial of
       service (DoS) attacks, including the pseudonym-based "Sybil
       attack."
     * Implementation: high-performance in-memory simulator
       (C++/Boost), asynchronous network daemon (Python) deployed on
       PlanetLab testbed.  Solo.
     * Supervised Master's thesis implementing secure SIP rendezvous
       over Whanau (Java).

  UIA
  http://pdos.csail.mit.edu/uia/
  -
  2006
     * Designed, implemented, debugged, and demoed a routing and naming
       system which ties together users' many personal devices (e.g.,
       laptops, phones, cameras, media players) into a coherent
       cluster.  After devices are named and introduced to each other,
       UIA ensures that they can communicate whenever physically
       possible.  Users can refer to each others' devices by recursive
       names such as *phone.dad.bob*.
     * Novelty: UIA maintains a shared, concurrently-modified namespace
       across intermittently-connected devices, and securely propagates
       peer-to-peer updates without relying on a master server.
     * Implementation: routing module and kernel hooks (C++/Boost), UI
       (C++/QT), name database and resolver (Python).
       Team: 4 core developers, 2 PIs.
       Also incorporated into a Nokia product demo.

  Eyo
  http://pdos.csail.mit.edu/eyo/
  -
  2009
     * Continues the UIA project. Eyo is a data storage system and API
       which provides a consistent view of a user's data objects (e.g.,
       photos, music, email) across all of her devices.  Eyo tracks
       object updates, forwards changes to running applications,
       handles network partitions and concurrent updates, and
       proactively partitions and replicates data across heterogeneous
       devices.
     * Novelty: Eyo separates objects' metadata from their content and
       distributes all metadata to all devices, while partially
       replicating content to some devices.
     * Implementation: storage system (Python), C API (C/D-Bus),
       example applications (Python and C).
       Team: 3 core developers, 1 collaborator, 2 PIs.

  Alpaca
  http://pdos.csail.mit.edu/alpaca/
  -
  2007
     * Invented and implemented a logic-based proof-carrying
       authorization protocol.  Alpaca provides an API enabling network
       applications to state and prove logical assertions such as "the
       principal Alice says to delete the file X" using cryptographic
       operations specified in the accompanying proof.
     * Novelty: verifiers don't care how the proof is structured, as
       long as it is valid. Thus, Alpaca permits provers to use
       different cryptographic techniques (e.g., new hash functions or
       data transport mechanisms) without breaking compatibility with
       existing verifiers.  Alpaca's flexibility is more "future-proof"
       than crypto protocols such as Kerberos and TLS, which can only
       be updated by installing new software.
     * Implementation: logic language, logic engine, cryptography, test
       suites, demos (Python).  Solo.

  Barnraising
  http://pdos.csail.mit.edu/barnraising/
  -
  2003
     * Designed and implemented a peer-to-peer content distribution
       network (CDN).  Barnraising enables Web sites to delegate some
       of their load to a distributed network of cooperating cache
       hosts.
     * Novelty: Barnraising uses a new technique called SSL Splitting
       to securely serve data using untrusted caches.  Because a
       malicious cache cannot send clients bogus data, Barnraising can
       safely permit any Internet host to contribute cache space. Other
       systems are limited to centrally-controlled cache servers.
     * Implementation: SSL Splitting library (drop-in replacement for
       popular OpenSSL library, C), caching Web proxy, tracker, and DNS
       server (Perl).  Solo.

See also
     * CV: <http://lesniewski.org/cv.pdf>
     * Twitter: <http://twitter.com/lesniewski>
     * LinkedIn: <http://www.linkedin.com/in/chrislesniewski>
     * Facebook: <http://www.facebook.com/lesniewski>
