# moos-ivp-upstream
This is a personal fork of the MIT CSAIL MOOS-IvP source code base hosted at www.moos-ivp.org.  
It was created to serve the following purposes:
   1) Enable proper out-of-source builds that expose *all* libraries and binaries for easier inclusion in external projects.
   2) Remove missions, data, and out-of-date documentation that is not necessary to build and bloats the moos-ivp repository.
   3) Use git for source control.

Building sources the Easy Way:
-----------------------------------
Run the provided script to build the MOOS and MOOS-IvP source trees in an out-of-source build:

<code>
   <repo path>/build.sh
</code>

Executables produced by the build are written to <repo path>/bin.
Libraries produced by the build *including libproj* are written to <repo path>/lib

