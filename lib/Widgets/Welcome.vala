/*
 * Copyright (c) 2012 Victor Eduardo
 * Copyright (C) 2011 Maxwell Barvian
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 */

using Gtk;

public class Granite.Widgets.Welcome : Gtk.EventBox {

    // Signals
    public signal void activated (int index);

    protected new GLib.List<Gtk.Button> children = new GLib.List<Gtk.Button> ();
    protected Gtk.Box options;

    private enum CaseConversionMode {
        TITLE,
        SENTENCE
    }

    public Welcome (string title_text, string subtitle_text) {
        string _title_text = modify_text_case (title_text, CaseConversionMode.TITLE);
        string _subtitle_text = modify_text_case (subtitle_text, CaseConversionMode.SENTENCE);

        Gtk.Box content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        // Set theming
        this.get_style_context().add_class ("GraniteWelcomeScreen");

        // Box properties
        content.homogeneous = false;

        // Top spacer
        content.pack_start (new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0), true, true, 0);

        // Labels
        var title = new Gtk.Label ("<span weight='medium' size='14700'>" + _title_text + "</span>");

        title.get_style_context().add_class ("title");

        title.use_markup = true;
        title.set_justify (Gtk.Justification.CENTER);
        content.pack_start (title, false, true, 0);

        var subtitle = new Gtk.Label ("<span weight='medium' size='11500'>" + _subtitle_text + "</span>");
        subtitle.use_markup = true;
        subtitle.sensitive = false;
        subtitle.set_justify (Gtk.Justification.CENTER);
        content.pack_start (subtitle, false, true, 2);

        subtitle.get_style_context().add_class("subtitle");

        // Options wrapper
        this.options = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
        var options_wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        options_wrapper.pack_start (new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0), true, true, 0); // left padding
        options_wrapper.pack_start (this.options, false, false, 0); // actual options
        options_wrapper.pack_end (new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0), true, true, 0); // right padding

        content.pack_start (options_wrapper, false, false, 20);

        // Bottom spacer
        content.pack_end (new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0), true, true, 0);

        add (content);
    }

    public void set_sensitivity (uint index, bool val) {
        if(index < children.length () && children.nth_data (index) is Gtk.Widget)
            children.nth_data (index).set_sensitive (val);
    }

    public void append (string icon_name, string option_text, string description_text) {
        Gtk.Image? image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        append_with_image (image, option_text, description_text);
    }

    public void append_with_pixbuf (Gdk.Pixbuf? pixbuf, string option_text, string description_text) {
        var image = new Gtk.Image.from_pixbuf (pixbuf);
        append_with_image (image, option_text, description_text);
    }

    public void append_with_image (Gtk.Image? image, string option_text, string description_text) {
        string _option_text = modify_text_case (option_text, CaseConversionMode.TITLE);
        string _description_text = modify_text_case (description_text, CaseConversionMode.SENTENCE);

        // Option label
        var label = new Gtk.Label ("<span weight='medium' size='11700'>" + _option_text + "</span>");
        label.use_markup = true;
        label.halign = Gtk.Align.START;
        label.valign = Gtk.Align.CENTER;
        label.get_style_context().add_class ("option-title");

        // Description label
        var description = new Gtk.Label ("<span weight='medium' size='11400'>" + _description_text + "</span>");
        description.use_markup = true;
        description.halign = Gtk.Align.START;
        description.valign = Gtk.Align.CENTER;
        description.sensitive = false;
        description.get_style_context().add_class ("option-description");

        // Button
        var button = new Gtk.Button ();
        button.set_relief (Gtk.ReliefStyle.NONE);

        // Button contents wrapper
        var button_contents = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 7);

        // Add left image
        if (image != null) {
            image.set_pixel_size (48);
            button_contents.pack_start (image, false, true, 8);
        }

        // Add right text wrapper
        var text_wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        // top spacing
        text_wrapper.pack_start (new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0), true, true, 0);
        text_wrapper.pack_start (label, false, false, 0);
        text_wrapper.pack_start (description, false, false, 0);
        // bottom spacing
        text_wrapper.pack_end (new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0), true, true, 0);

        button_contents.pack_start (text_wrapper, false, true, 8);

        button.add (button_contents);
        children.append (button);
        options.pack_start (button, false, false, 0);

        button.button_release_event.connect ( () => {
            int index = this.children.index (button);
            activated (index); // send signal
            return false;
        } );
    }

    private string modify_text_case (string text, CaseConversionMode mode) {

        /**
         * This function will not modify the text if any the following conditions are met:
         * - @text ends with a dot.
         * - @text contains at least one character outside the English alphabet.
         */

        var fixed_text = new StringBuilder ();
        unichar c;

        // Disabling this feature for other languages
        for (int i = 0; text.get_next_char (ref i, out c);) {
            if (c.isgraph () && !('a' <= c.tolower () && c.tolower () <= 'z'))
                return text;
        }
        // Checking if @text ends with a dot.
        if (c == '.')
            return text;

        switch (mode) {
            case CaseConversionMode.TITLE:
                unichar last_char = ' ';
                for (int i = 0; text.get_next_char (ref i, out c);) {
                    if (last_char.isspace () && c.islower ())
                        fixed_text.append_unichar (c.totitle ());
                    else
                        fixed_text.append_unichar (c);

                    last_char = c;
                }
                break;
            case CaseConversionMode.SENTENCE:
                bool fixed = false;
                unichar last_char = ' ';
                for (int i = 0; text.get_next_char (ref i, out c);) {
                    if (!fixed && last_char.isspace ()) {
                        if (c.islower ())
                            fixed_text.append_unichar (c.totitle ());
                        else
                            fixed_text.append_unichar (c);
                        fixed = true;
                    }
                    else {
                        fixed_text.append_unichar (c);
                    }
                }
                fixed_text.append_unichar ('.');
                break;
        }

        return fixed_text.str;
    }
}

