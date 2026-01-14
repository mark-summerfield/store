# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval gui_highlight {}

proc color_for_kind kind {
    switch $kind {
        bool         { return #228B22 ;# dark green }
        comment      { return #666666 ;# dark grey }
        conditional  { return darkblue }
        consts       { return #228B22 ;# mid green }
        constcmd     { return navy }
        embedded_sql { return orange }
        exception    { return red }
        flags        { return #80604D ;# brown }
        function     { return blue }
        gui          { return #0000CD ;# medium blue }
        var          { return purple }
        meta         { return darkcyan }
        number       { return #B400B4 ;# bright purple }
        oo           { return #80604D ;# mid brown }
        op           { return #008800 ;# green }
        str          { return #888000 ;# gold }
        tkcmd        { return steelblue }
        type         { return navy }
    }
}

proc gui_highlight::highlight_tcl txt {
    ctext::addHighlightClassForRegexp $txt comment \
        [color_for_kind comment] {(?n)#.*}
    $txt tag configure comment -font MonoItalic
    ctext::addHighlightClass $txt cmd [color_for_kind function] [list \
        after append array bgerror binary break buildinfo callback \
        cd chan classvariable clock close concat configure continue \
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
    ctext::addHighlightClass $txt gvars [color_for_kind var] [list \
        argc argv argv0 auto_execok auto_import auto_load auto_mkindex \
        auto_path auto_qualify auto_reset tcl_endOfWord tcl_findLibrary \
        tcl_interactive tcl_library tcl_nonwordchars tcl_patchLevel \
        tcl_pkgPath tcl_platform tcl_rcFileName tcl_startOfNextWord \
        tcl_startOfPreviousWord tcl_traceCompile tcl_traceExec \
        tcl_version tcl_wordBreakAfter tcl_wordBreakBefore tcl_wordchars \
        tcltest]
    ctext::addHighlightClass $txt bools [color_for_kind bool] [list \
        true false on off yes no]
    ctext::addHighlightClass $txt proccmd [color_for_kind meta] [list \
        apply coroutine proc return tailcall yield yieldto]
    $txt tag configure proccmd -font MonoBold
    ctext::addHighlightClass $txt conditional [color_for_kind conditional] \
        [list if then else elseif switch catch try throw raise finally \
         default while for foreach break continue]
    $txt tag configure conditional -font MonoBold
    ctext::addHighlightClass $txt tkcmd [color_for_kind tkcmd] [list \
        lower raise print selection send]
    ctext::addHighlightClass $txt widget [color_for_kind gui] [list \
        bell bind bindtags bitmap busy button canvas checkbutton \
        clipboard console destroy entry event focus font fontchooser \
        frame geometry grab grid image label labelframe listbox menu \
        menubutton message option pack panedwindow photo place \
        radiobutton safe::loadTk scale scrollbar spinbox sysnotify \
        systray text tk tk::scalingPct tk::svgFmt tk_bisque \
        tk_chooseColor tk_chooseDirectory tk_dialog tk_focusFollowsMouse \
        tk_focusNext tk_focusPrev tk_getOpenFile tk_getSaveFile \
        tk_library tk_menuSetFocus tk_messageBox tk_optionMenu \
        tk_patchLevel tk_popup tk_setPalette tk_strictMotif tk_textCopy \
        tk_textCut tk_textPaste tk_version tkerror tkwait toplevel \
        ttk::button ttk::checkbutton ttk::combobox ttk::entry ttk::frame \
        ttk::label ttk::labelframe ttk::menubutton ttk::notebook \
        ttk::panedwindow ttk::progressbar ttk::radiobutton ttk::scale \
        ttk::scrollbar ttk::separator ttk::sizegrip ttk::spinbox \
        ttk::style ttk::treeview ttk::widget ttk_image winfo wm]
    ctext::addHighlightClass $txt flags [color_for_kind flags] [list \
        -text -command -yscrollcommand -xscrollcommand -background \
        -foreground -fg -bg -highlightbackground -y -x -highlightcolor \
        -relief -width -height -wrap -font -fill -side -outline -style \
        -insertwidth -textvariable -activebackground -activeforeground \
        -insertbackground -anchor -orient -troughcolor -nonewline -expand \
        -type -message -title -offset -in -after -yscroll -xscroll \
        -forward -regexp -count -exact -padx -ipadx -filetypes -all -from \
        -to -label -value -variable -regexp -backwards -forwards -bd \
        -pady -ipady -state -row -column -cursor -highlightcolors \
        -linemap -menu -tearoff -displayof -cursor -underline -tags -tag]
    ctext::addHighlightClassWithOnlyCharStart $txt vars \
        [color_for_kind var] "\$"
    ctext::addHighlightClassForSpecialChars $txt special \
        [color_for_kind op] {[]{}:?;}
    ctext::addHighlightClassForRegexp $txt const [color_for_kind consts] \
        {(?:const )[:\w]+}
    ctext::addHighlightClass $txt constcmd [color_for_kind constcmd] [list \
        const]
    $txt tag configure constcmd -font MonoBold
    ctext::addHighlightClassForRegexp $txt simplestring \
        [color_for_kind str] {(?s)".*?"}
    ctext::addHighlightClassForRegexp $txt number [color_for_kind number] \
        {[-+]?\d+(\.\d+([Ee][-+]?\d+))?|0[xX][\dA-Fa-f]+|0[bB][01]+}
    ctext::addHighlightClass $txt oo [color_for_kind oo] [list classmethod \
        constructor destructor export forward initialize initialise \
        method private self my superclass unexport myclass mymethod \
        oo::Slot oo::abstract oo::class oo::configurable oo::copy \
        oo::define oo::objdefine oo::object oo::singleton]
    $txt tag configure oo -font MonoBold
    ctext::addHighlightClass $txt sql [color_for_kind embedded_sql] [list \
        AFTER AND ALTER AS ASC BEFORE BEGIN BETWEEN BY CASE CHECK COLUMN \
        CREATE DEFAULT DELETE DESC DISTINCT DROP EACH END EXISTS FOR \
        FOREIGN FROM GROUP HAVING IF IN INDEX INSERT INTO IS JOIN KEY \
        LIKE LIMIT NOT NULL ON OR ORDER PRIMARY REFERENCES RENAME REPLACE \
        ROW SELECT SET TABLE TO TRIGGER UNION UNIQUE UPDATE VALUES VIEW \
        WHEN WHERE WITH]
}

proc gui_highlight::highlight_sql txt {
    ctext::addHighlightClassForRegexp $txt comment \
        [color_for_kind comment] {(?n)--.*}
    $txt tag configure comment -font MonoItalic
    ctext::addHighlightClass $txt cmd [color_for_kind function] [list \
        AFTER AND ALTER AS ASC BEFORE BEGIN BETWEEN BY CASE CHECK COLUMN \
        CREATE DEFAULT DELETE DESC DISTINCT DROP EACH END EXISTS FOR \
        FOREIGN FROM GROUP HAVING IF IN INDEX INSERT INTO IS JOIN KEY \
        LIKE LIMIT NOT NULL ON OR ORDER PRIMARY REFERENCES RENAME REPLACE \
        ROW SELECT SET TABLE TO TRIGGER UNION UNIQUE UPDATE VALUES VIEW \
        WHEN WHERE WITH]
    ctext::addHighlightClass $txt types [color_for_kind type] [list \
        INTEGER REAL BLOB TEXT BOOL DATE DATETIME]
    ctext::addHighlightClass $txt meta [color_for_kind meta] [list PRAGMA]
    ctext::addHighlightClass $txt bools [color_for_kind bool] [list \
        NULL TRUE FALSE]
    ctext::addHighlightClassForRegexp $txt number [color_for_kind number] \
        {[-+]?\d+(\.\d+([Ee][-+]?\d+))?|0[xX][\dA-Fa-f]+|0[bB][01]+}
    ctext::addHighlightClassForRegexp $txt string [color_for_kind str] \
        {'[^\n\r]*?'}
    ctext::addHighlightClass $txt except [color_for_kind exception] [list \
        RAISE ABORT]
    ctext::addHighlightClassForRegexp $txt op [color_for_kind op] \
        {(?:=|!=|<|<=|>|>=)}
    ctext::addHighlightClass $txt funcs [color_for_kind function] [list \
        ABS CHANGES CHAR COALESCE CONCAT CONCAT_WS FORMAT GLOB HEX IFNULL \
        IIF INSTR LAST_INSERT_ROWID LENGTH LIKELIHOOD LIKELY \
        LOAD_EXTENSION LOWER LTRIM MAX MIN NULLIF OCTET_LENGTH PRINTF \
        QUOTE RANDOM RANDOMBLOB ROUND RTRIM SIGN SOUNDEX SUBSTR SUBSTRING \
        TRIM TYPEOF UNHEX UNLIKELY UPPER ZEROBLOB]
}
