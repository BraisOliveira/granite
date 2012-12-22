// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN ICENSE

    Copyright (C) 2011-2012 Tom Beckmann <tom@elementaryos.org>
    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

namespace Granite.Widgets {

    /**
     * This is a standard tab which can be used in a notebook to form a tabbed UI.
     */
    public class Tab : Gtk.Box {
        Gtk.Label _label;
        public string label {
            get { return _label.label;  }
            set { _label.label = value; }
        }

        internal Gtk.EventBox page_container;
        public Gtk.Widget page {
            get {
                return page_container.get_child ();
            }
            set {
                if (page_container.get_child () != null)
                    page_container.remove (page_container.get_child ());

                page_container.add (value);
                page_container.show_all ();
            }
        }

        internal Gtk.Image _icon;
        public GLib.Icon? icon {
            owned get { return _icon.gicon;  }
            set { _icon.gicon = value; }
        }

        Gtk.Spinner _working;
        bool __working;
        public bool working {
            get { return __working; }
            set { __working = _working.visible = value; _icon.visible = !value; }
        }

        public Pango.EllipsizeMode ellipsize_mode {
            get { return _label.ellipsize; }
            set { _label.ellipsize = value; }
        }

        bool _fixed;
        public bool fixed {
            get { return _fixed; }
            set {
                if (value != _fixed) {
                    _label.visible = value;
                    close.visible = value;
                }
                _fixed = value;
            }
        }

        internal Gtk.Button close;
        public Gtk.Menu menu { get; set; }

        //we need to be able to toggle those from the notebook
        internal Gtk.MenuItem new_window_m;
        internal Gtk.MenuItem duplicate_m;

        internal signal void closed ();
        internal signal void close_others ();
        internal signal void new_window ();
        internal signal void duplicate ();

        public Tab (string label="", GLib.Icon? icon=null, Gtk.Widget? page=null) {
            this._label = new Gtk.Label (label);
            if (icon != null)
                this._icon = new Gtk.Image.from_gicon (icon, Gtk.IconSize.MENU);
            else
                this._icon = new Gtk.Image.from_stock (Gtk.Stock.MISSING_IMAGE, Gtk.IconSize.MENU);
            this._working = new Gtk.Spinner ();
            _working.start();
            this.close = new Gtk.Button ();

            close.add (new Gtk.Image.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU));
            close.tooltip_text = _("Close tab");
            close.relief = Gtk.ReliefStyle.NONE;

            var lbl = new Gtk.EventBox ();
            _label.set_tooltip_text (label);
            lbl.add (_label);
            _label.ellipsize = Pango.EllipsizeMode.END;
            lbl.visible_window = false;

            this.pack_start (this.close, false);
            this.pack_start (lbl);
            this.pack_start (this._icon, false);
            this.pack_start (this._working, false);

            page_container = new Gtk.EventBox ();
            page_container.add (page ?? new Gtk.Label (""));
            page_container.show_all ();

            this.show_all ();

            menu = new Gtk.Menu ();
            var close_m = new Gtk.MenuItem.with_label (_("Close Tab"));
            var close_other_m = new Gtk.MenuItem.with_label ("");
            new_window_m = new Gtk.MenuItem.with_label (_("Open in a new Window"));
            duplicate_m = new Gtk.MenuItem.with_label (_("Duplicate"));
            menu.append (close_other_m);
            menu.append (close_m);
            menu.append (new_window_m);
            menu.append (duplicate_m);
            menu.show_all ();

            close_m.activate.connect (() => closed () );
            close_other_m.activate.connect (() => close_others () );
            new_window_m.activate.connect (() => new_window () );
            duplicate_m.activate.connect (() => duplicate () );

            lbl.button_press_event.connect ((e) => {
                if (e.button == 2 && close.visible) { //if !close.visible, closable if false
                    this.closed ();
                    return true;
                } else if (e.button == 3) {
                    menu.popup (null, null, null, 3, e.time);
                    uint num_tabs = (this.get_parent () as Gtk.Container).get_children ().length ();
                    close_other_m.label = ngettext ("Close Other Tab", "Close Other Tabs", num_tabs);
                    if (num_tabs == 1)
                        close_other_m.sensitive = false;
                    return true;
                }

                return false;
            });

            /* Disable the double click signal on the tab */
            this.button_press_event.connect ((e) => {
                return (e.type == Gdk.EventType.2BUTTON_PRESS);
            });

            page_container.button_press_event.connect (() => { return true; }); //dont let clicks pass through
            close.clicked.connect ( () => this.closed () );
            working = false;
        }
    }

    public class DynamicNotebook : Gtk.EventBox {

        /**
         * number of pages
         */
        public int n_tabs {
            get { return notebook.get_n_pages (); }
        }

        /**
         * Hide the tab bar and only show the pages
         */
        public bool show_tabs {
            get { return notebook.show_tabs;  }
            set { notebook.show_tabs = value; }
        }

        bool _show_icons;
        /**
         * Toggle icon display
         */
        public bool show_icons {
            get { return _show_icons; }
            set {
                if (_show_icons != value) {
                    tabs.foreach ((t) => t._icon.visible = value );
                }
                _show_icons = value;
            }
        }

        /**
         * Hide the close buttons and disable closing of tabs
         */
        bool _tabs_closable = true;
        public bool tabs_closable {
            get { return _tabs_closable; }
            set {
                if (value != _tabs_closable)
                    tabs.foreach ((t) => {
                            t.close.visible = value;
                        });
                _tabs_closable = value;
            }
        }

        /**
         * Make tabs reorderable
         */
        bool _allow_drag = true;
        public bool allow_drag {
            get { return _allow_drag; }
            set {
                _allow_drag = value;
                this.tabs.foreach ((t) => {
                    notebook.set_tab_reorderable (t.page_container, value);
                });
            }
        }

        /**
         * Allow creating new windows by dragging a tab out
         */
        bool _allow_new_window = false;
        public bool allow_new_window {
            get { return _allow_new_window; }
            set {
                _allow_new_window = value;
                this.tabs.foreach ((t) => {
                    notebook.set_tab_detachable (t.page_container, value);
                });
            }
        }

        /**
         * Allow duplicating tabs
         */
        bool _allow_duplication = false;
        public bool allow_duplication {
            get { return _allow_duplication; }
            set {
                _allow_duplication = value;

                foreach (var tab in tabs) {
                    tab.duplicate_m.visible = value;
                }
            }
        }

        public Tab current {
            get { return tabs.nth_data (notebook.get_current_page ()); }
            set { notebook.set_current_page (tabs.index (value)); }
        }

        GLib.List<Tab> _tabs;
        public GLib.List<Tab> tabs {
            get {
                _tabs = new GLib.List<Tab> ();
                for (var i = 0; i < n_tabs; i++) {
                    _tabs.append (notebook.get_tab_label (notebook.get_nth_page (i)) as Tab);
                }
                return _tabs;
            }
        }

        public string group_name {
            get { return notebook.group_name; }
            set { notebook.group_name = value; }
        }

        /**
         * The menu appearing when the notebook is clicked on a blank space
         */
        public Gtk.Menu menu { get; private set; }

        Gtk.Notebook notebook;
        private Gtk.CssProvider button_fix;

        private int tab_width = 150;
        private int max_tab_width = 150;

        public signal void tab_added (Tab tab);
        public signal bool tab_removed (Tab tab);
        Tab? old_tab; //stores a reference for tab_switched
        public signal void tab_switched (Tab? old_tab, Tab new_tab);
        public signal void tab_moved (Tab tab, int new_pos, bool new_window, int x, int y);
        public signal void tab_duplicated (Tab duplicated_tab);

        private static const string CLOSE_BUTTON_STYLE = """
        * {
            -GtkButton-default-border : 0;
            -GtkButton-default-outside-border : 0;
            -GtkButton-inner-border: 0;
            -GtkWidget-focus-line-width : 0;
            -GtkWidget-focus-padding : 0;
            padding: 0;
        }
        """;

        /**
         * Create a new dynamic notebook
         */
        public DynamicNotebook () {

            this.button_fix = new Gtk.CssProvider ();
            try {
                this.button_fix.load_from_data (CLOSE_BUTTON_STYLE, -1);
            } catch (Error e) { warning (e.message); }

            this.notebook = new Gtk.Notebook ();
            this.visible_window = false;
            this.get_style_context ().add_class ("dynamic-notebook");

            this.notebook.scrollable = true;
            this.notebook.show_border = false;

            this.draw.connect ( (ctx) => {
                this.get_style_context ().render_activity (ctx, 0, 0, this.get_allocated_width (), 27);
                return false;
            });

            this.add (this.notebook);

            menu = new Gtk.Menu ();

            var new_tab_m = new Gtk.MenuItem.with_label (_("New Tab"));
            menu.append (new_tab_m);

            menu.show_all ();

            new_tab_m.activate.connect (() => {
                var t = new Tab ();
                notebook.page = (int) this.insert_tab (t, -1);
                this.tab_added (t);
            });

            this.button_press_event.connect ((e) => {
                if (e.type == Gdk.EventType.2BUTTON_PRESS && e.button == 1) {
                    var t = new Tab ();
                    notebook.page = (int) this.insert_tab (t, -1);
                    this.tab_added (t);
                } else if (e.button == 3) {
                    menu.popup (null, null, null, 3, e.time);
                }

                return false;
            });

            var add = new Gtk.Button ();
            add.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU));
            add.margin_left = 6;
            add.relief = Gtk.ReliefStyle.NONE;
            add.tooltip_text = _("New tab");
            this.notebook.set_action_widget (add, Gtk.PackType.START);
            add.show_all ();
            add.get_style_context ().add_provider (button_fix, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            add.clicked.connect ( () => {
                var t = new Tab ();
                notebook.page = (int) this.insert_tab (t, -1);
                this.tab_added (t);
            });

            this.size_allocate.connect (() => {
                this.recalc_size ();
            });

            this.key_press_event.connect ((e) => {
                switch (e.keyval) {
                    case Gdk.Key.W: //ctrl+w
                        if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                            if (!tabs_closable) break;
                            remove_tab (current);
                        }

                        break;
                    case Gdk.Key.T:
                        if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                            var t = new Tab ();
                            this.tab_added (t);
                            notebook.page = (int) this.insert_tab (t, -1);
                            return true;
                        }

                        break;
                    case Gdk.Key.Page_Up:
                        if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                            next_page ();
                            return true;
                        }

                        break;
                    case Gdk.Key.Page_Down:
                        if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                            previous_page ();
                            return true;
                        }

                        break;
                    case Gdk.Key.@1:
                    case Gdk.Key.@2:
                    case Gdk.Key.@3:
                    case Gdk.Key.@4:
                    case Gdk.Key.@5:
                    case Gdk.Key.@6:
                    case Gdk.Key.@7:
                    case Gdk.Key.@8:
                        if ((e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                            var i = e.keyval - 49;
                            notebook.page = (int) ((i >= notebook.get_n_pages ()) ?
                                                   notebook.get_n_pages () - 1 : i);
                            return true;
                        }
                        break;
                    case Gdk.Key.@9:
                        if ((e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                            notebook.page = notebook.get_n_pages () - 1;
                        }

                        break;
                }

                return false;
            });

            notebook.switch_page.connect (on_switch_page);
            notebook.page_reordered.connect (on_page_reordered);
            notebook.create_window.connect (on_create_window);
        }

        ~Notebook () {
            notebook.switch_page.disconnect (on_switch_page);
            notebook.page_reordered.disconnect (on_page_reordered);
            notebook.create_window.disconnect (on_create_window);
        }

        void on_switch_page (Gtk.Widget page, uint pagenum) {
            var new_tab = notebook.get_tab_label (page) as Tab;

            tab_switched (old_tab, new_tab);
            old_tab = new_tab;
        }

        void on_page_reordered (Gtk.Widget page, uint pagenum) {
            tab_moved (notebook.get_tab_label (page) as Tab, (int) pagenum, false, -1, -1);
        }

        unowned Gtk.Notebook on_create_window (Gtk.Widget page, int x, int y) {
            var tab = notebook.get_tab_label (page) as Tab;
            notebook.remove_page (notebook.page_num (tab.page_container));

            tab_moved (tab, 0, true, x, y);
            return null;
        }

        private void recalc_size () {
            if (n_tabs == 0)
                return;

            var offset = 130;
            this.tab_width = (this.get_allocated_width () - offset) / this.notebook.get_n_pages ();
            if (tab_width > max_tab_width)
                tab_width = max_tab_width;

            if (tab_width < 0)
                tab_width = 0;

            for (var i = 0; i < this.notebook.get_n_pages (); i++) {
                this.notebook.get_tab_label (this.notebook.get_nth_page (i)).width_request = tab_width;
            }
        }

        public void remove_tab (Tab tab) {
            if (Signal.has_handler_pending (this, Signal.lookup ("tab-removed", typeof (DynamicNotebook)), 0, true)) {
                var sure = tab_removed (tab);
                if (!sure)
                    return;
            }

            var pos = get_tab_position (tab);
            if (pos != -1)
                notebook.remove_page (pos);
        }

        public void next_page () {
            this.notebook.page = this.notebook.page + 1 >= this.notebook.get_n_pages () ? this.notebook.page = 0 : this.notebook.page + 1;
        }

        public void previous_page () {
            this.notebook.page = this.notebook.page - 1 < 0 ?
                                 this.notebook.page = this.notebook.get_n_pages () - 1 : this.notebook.page - 1;
        }

        public override void show () {
            base.show ();
            notebook.show ();
        }

        public new List<Gtk.Widget> get_children () {
            var list = new List<Gtk.Widget> ();

            foreach (var child in notebook.get_children ()) {
                list.append ((child as Gtk.Container).get_children ().nth_data (0));
            }

            return list;
        }

        public int get_tab_position (Tab tab) {
            return this.notebook.page_num (tab.page_container);
        }

        public void set_tab_position (Tab tab, int position) {
            notebook.reorder_child (tab.page_container, position);
            tab_moved (tab, position, false, -1, -1);
        }

        public Tab? get_tab_by_index (int index) {
            return notebook.get_tab_label (notebook.get_nth_page (index)) as Tab;
        }

        public Tab? get_tab_by_widget (Gtk.Widget widget) {
            return notebook.get_tab_label (widget.get_parent ()) as Tab;
        }

        public Gtk.Widget get_nth_page (int index) {
            return notebook.get_nth_page (index);
        }

        public uint insert_tab (Tab tab, int index) {
            return_if_fail (tabs.index (tab) < 0);

            var i = 0;
            if (index == -1)
                i = this.notebook.insert_page (tab.page_container, tab, this.notebook.get_n_pages ());
            else
                i = this.notebook.insert_page (tab.page_container, tab, index);

            this.notebook.set_tab_reorderable (tab.page_container, this.allow_drag);
            this.notebook.set_tab_detachable  (tab.page_container, this.allow_new_window);

            tab._icon.visible = show_icons;
            tab.duplicate_m.visible = allow_duplication;
            tab.new_window_m.visible = allow_new_window;

            tab.width_request = tab_width;
            tab.close.get_style_context ().add_provider (button_fix,
                                                         Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            tab.closed.connect ( () => {
                remove_tab (tab);
            });

            tab.close_others.connect ( () => {
                var num = 0; //save num, in case a tab refused to close so we don't end up in an infinite loop

                for (var j = 0; j < tabs.length (); j++) {
                    if (tab != tabs.nth_data (j)) {
                        tabs.nth_data (j).closed ();
                        if (num == n_tabs) break;
                        j--;
                    }

                    num = n_tabs;
                }
            });

            tab.new_window.connect (() => {
                notebook.remove_page (notebook.page_num (tab.page_container));
                tab_moved (tab, 0, true, 0, 0);
            });

            tab.duplicate.connect (() => {
                tab_duplicated (tab);
            });

            this.recalc_size ();

            if (!tabs_closable)
                tab.close.visible = false;

            return i;
        }
    }
}