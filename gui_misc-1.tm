# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require ctext 3
package require ntext 1
package require ui

namespace eval gui_misc {
    variable Ext ""
}

proc gui_misc::make_text_frame {} {
    set frame [ttk::frame .textFrame]
    set name text
    set txt [ctext $frame.text -wrap word -font Mono -linemapbg gray90]
    ui::scrollize $frame $name vertical
    bindtags $txt {$txt Ntext . all}
    $txt tag configure sel -selectbackground yellow
    list $frame $txt
}

proc gui_misc::set_tree_tags tree {
    foreach {tag color} {parent blue untracked gray generation green \
                         updatable red} {
        $tree tag configure $tag -foreground $color
    }
}

proc gui_misc::refresh_highlighting {txt ext} {
    if {$ext ne $::gui_misc::Ext} {
        set ::gui_misc::Ext $ext
        ctext::clearHighlightClasses $txt
        switch $ext {
            .tcl - .tm { gui_misc::highlight_tcl $txt }
        }
    }
}

proc gui_misc::highlight_tcl txt {
    ctext::addHighlightClassForRegexp $txt comment #666666 {#[^\n\r]*}
    $txt tag configure comment -font MonoItalic
    ctext::addHighlightClass $txt cmd blue [list after append \
        array bgerror binary break buildinfo callback cd chan \
        classvariable clock close concat configure const continue \
        cookiejar coroinject coroprobe dde dict encoding env \
        eof error errorCode errorInfo eval exec exit expr fblocked \
        fconfigure fcopy file fileevent flush for foreach foreachLine \
        format fpclassify gets glob global history http incr info \
        interp join lappend lassign ledit lindex link linsert list \
        llength lmap load lpop lrange lremove lrepeat lreplace lreverse \
        lsearch lseq lset lsort mathfunc memory msgcat namespace next \
        nextto open package parray pid pkg::create pkg_mkIndex \
        platform platform::shell property puts pwd read readFile \
        refchan regexp registry regsub rename safe scan seek self \
        set socket source split string subst tcl::idna \
        tcl::prefix tcl::process tcltest tell time timerate tm \
        trace transchan unknown unload unset update uplevel upvar \
        variable vwait while writeFile zipfs zlib]
    $txt tag configure cmd -font MonoBold
    ctext::addHighlightClass $txt gvars purple [list argc argv argv0 \
        auto_execok auto_import auto_load auto_mkindex auto_path \
        auto_qualify auto_reset tcl_endOfWord tcl_findLibrary \
        tcl_interactive tcl_library tcl_nonwordchars tcl_patchLevel \
        tcl_pkgPath tcl_platform tcl_rcFileName tcl_startOfNextWord \
        tcl_startOfPreviousWord tcl_traceCompile tcl_traceExec \
        tcl_version tcl_wordBreakAfter tcl_wordBreakBefore tcl_wordchars \
        tcltest]
    ctext::addHighlightClass $txt bools #228B22 [list true false on off \
        yes no]
    ctext::addHighlightClass $txt proccmd darkcyan [list apply coroutine \
        proc return tailcall yield yieldto]
    $txt tag configure proccmd -font MonoBold
    ctext::addHighlightClass $txt conditional darkblue [list if then else \
        elseif switch catch try throw raise finally default while for \
        foreach break continue]
    $txt tag configure conditional -font MonoBold
    ctext::addHighlightClass $txt tkcmd steelblue [list lower raise \
        print selection send]
    ctext::addHighlightClass $txt widget blue [list bell bind bindtags \
        bitmap busy button canvas checkbutton clipboard console destroy \
        entry event focus font fontchooser frame geometry grab grid \
        image label labelframe listbox menu menubutton message option \
        pack panedwindow photo place radiobutton safe::loadTk scale \
        scrollbar spinbox sysnotify systray text tk tk::scalingPct \
        tk::svgFmt tk_bisque tk_chooseColor tk_chooseDirectory tk_dialog \
        tk_focusFollowsMouse tk_focusNext tk_focusPrev tk_getOpenFile \
        tk_getSaveFile tk_library tk_menuSetFocus tk_messageBox \
        tk_optionMenu tk_patchLevel tk_popup tk_setPalette tk_strictMotif \
        tk_textCopy tk_textCut tk_textPaste tk_version tkerror tkwait \
        toplevel ttk::button ttk::checkbutton ttk::combobox ttk::entry \
        ttk::frame ttk::label ttk::labelframe ttk::menubutton \
        ttk::notebook ttk::panedwindow ttk::progressbar ttk::radiobutton \
        ttk::scale ttk::scrollbar ttk::separator ttk::sizegrip \
        ttk::spinbox ttk::style ttk::treeview ttk::widget ttk_image winfo \
        wm]
    ctext::addHighlightClass $txt flags #80604D [list -text -command \
	-yscrollcommand -xscrollcommand -background -foreground -fg -bg \
	-highlightbackground -y -x -highlightcolor -relief -width -height \
	-wrap -font -fill -side -outline -style -insertwidth -textvariable \
	-activebackground -activeforeground -insertbackground -anchor \
	-orient -troughcolor -nonewline -expand -type -message -title \
	-offset -in -after -yscroll -xscroll -forward -regexp -count \
	-exact -padx -ipadx -filetypes -all -from -to -label -value \
	-variable -regexp -backwards -forwards -bd -pady -ipady -state \
	-row -column -cursor -highlightcolors -linemap -menu -tearoff \
	-displayof -cursor -underline -tags -tag]
    ctext::addHighlightClassWithOnlyCharStart $txt vars purple "\$"
    ctext::addHighlightClassForSpecialChars $txt special #008800 {[]{}:?;}
    ctext::addHighlightClassForRegexp $txt const #228B22 {(?:const )[:\w]+}
    ctext::addHighlightClass $txt constcmd navy [list const]
    $txt tag configure constcmd -font MonoBold
    ctext::addHighlightClassForRegexp $txt simplestring #888000 {(?s)".*?"}
    ctext::addHighlightClassForRegexp $txt number #B400B4 \
        {[-+]?\d+(\.\d+([Ee][-+]?\d+))?|0[xX][\dA-Fa-f]+|0[bB][01]+}
    ctext::addHighlightClass $txt oo #80604D [list classmethod \
        constructor destructor export forward initialize initialise \
        method private self my superclass unexport myclass mymethod \
        oo::Slot oo::abstract oo::class oo::configurable oo::copy \
        oo::define oo::objdefine oo::object oo::singleton]
    $txt tag configure oo -font MonoBold
}
