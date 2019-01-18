/*
 * Copyright (C) 2010 Collabora Ltd.
 * Copyright (C) 2013 Philip Withnall
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using GLib;
using Gee;
using Xml;
using Folks;

public class Folks.Importers.Pidgin : Folks.Importer
{
  private PersonaStore destination_store;
  private uint persona_count = 0;

  public override async uint import (PersonaStore destination_store,
      string? source_filename) throws ImportError
    {
      this.destination_store = destination_store;
      string filename = source_filename;

      /* Default filename */
      if (filename == null || filename.strip () == "")
        {
          filename = Path.build_filename (Environment.get_home_dir (),
              ".purple", "blist.xml", null);
        }

      var file = File.new_for_path (filename);
      if (!file.query_exists ())
        {
          /* Translators: the parameter is a filename. */
          throw new ImportError.MALFORMED_INPUT (_("File %s does not exist."),
              filename);
        }

      FileInfo file_info;
      try
        {
          file_info = yield file.query_info_async (
              FileAttribute.ACCESS_CAN_READ, FileQueryInfoFlags.NONE,
              Priority.DEFAULT);
        }
      catch (GLib.Error e)
        {
          throw new ImportError.MALFORMED_INPUT (
              /* Translators: the first parameter is a filename, and the second
               * is an error message. */
              _("Failed to get information about file %s: %s"), filename,
              e.message);
        }

      if (!file_info.get_attribute_boolean (FileAttribute.ACCESS_CAN_READ))
        {
          /* Translators: the parameter is a filename. */
          throw new ImportError.MALFORMED_INPUT (_("File %s is not readable."),
              filename);
        }

      Xml.Doc* xml_doc = Parser.parse_file (filename);

      if (xml_doc == null)
        {
          throw new ImportError.MALFORMED_INPUT (
              /* Translators: the parameter is a filename. */
              _("The Pidgin buddy list file ‘%s’ could not be loaded."),
              filename);
        }

      /* Check the root node */
      Xml.Node *root_node = xml_doc->get_root_element ();

      if (root_node == null || root_node->name != "purple" ||
          root_node->get_prop ("version") != "1.0")
        {
          /* Free the document manually before throwing because the garbage
           * collector can't work on pointers. */
          delete xml_doc;
          throw new ImportError.MALFORMED_INPUT (
              /* Translators: the parameter is a filename. */
              _("The Pidgin buddy list file ‘%s’ could not be loaded: the root element could not be found or was not recognized."),
              filename);
        }

      /* Parse each <blist> child element */
      for (Xml.Node *iter = root_node->children; iter != null;
          iter = iter->next)
        {
          if (iter->type != ElementType.ELEMENT_NODE || iter->name != "blist")
            continue;

          yield this.parse_blist (iter);
        }

      /* Tidy up */
      delete xml_doc;

      stdout.printf (
          /* Translators: the first parameter is the number of buddies which
           * were successfully imported, and the second is a filename. */
          ngettext ("Imported %u buddy from ‘%s’.",
              "Imported %u buddies from ‘%s’.", this.persona_count) + "\n",
          this.persona_count, filename);

      /* Return the number of Personas we imported */
      return this.persona_count;
    }

  private async void parse_blist (Xml.Node *blist_node)
    {
      for (Xml.Node *iter = blist_node->children; iter != null;
          iter = iter->next)
        {
          if (iter->type != ElementType.ELEMENT_NODE || iter->name != "group")
            continue;

          yield this.parse_group (iter);
        }
    }

  private async void parse_group (Xml.Node *group_node)
    {
      string group_name = group_node->get_prop ("name");

      for (Xml.Node *iter = group_node->children; iter != null;
          iter = iter->next)
        {
          if (iter->type != ElementType.ELEMENT_NODE || iter->name != "contact")
            continue;

          Persona persona = yield this.parse_contact (iter);

          /* Skip the persona if creating them failed or if they don't support
           * groups. */
          if (persona == null || !(persona is GroupDetails))
            continue;

          try
            {
              GroupDetails group_details = (GroupDetails) persona;
              yield group_details.change_group (group_name, true);
            }
          catch (GLib.Error e)
            {
              stderr.printf (
                  /* Translators: the first parameter is a persona identifier,
                   * and the second is an error message. */
                  _("Error changing group of contact ‘%s’: %s") + "\n",
                  persona.iid, e.message);
            }
        }
    }

  private async Persona? parse_contact (Xml.Node *contact_node)
    {
      string alias = null;
      var im_addresses = new HashMultiMap<string, ImFieldDetails> ();
      string im_address_string = "";

      /* Parse the <buddy> elements beneath <contact> */
      for (Xml.Node *iter = contact_node->children; iter != null;
          iter = iter->next)
        {
          if (iter->type != ElementType.ELEMENT_NODE || iter->name != "buddy")
            continue;

          string blist_protocol = iter->get_prop ("proto");
          if (blist_protocol == null)
            continue;

          string tp_protocol =
              this.blist_protocol_to_tp_protocol (blist_protocol);
          if (tp_protocol == null)
            continue;

          /* Parse the <name> and <alias> elements beneath <buddy> */
          for (Xml.Node *subiter = iter->children; subiter != null;
              subiter = subiter->next)
            {
              if (subiter->type != ElementType.ELEMENT_NODE)
                continue;

              if (subiter->name == "alias")
                alias = subiter->get_content ();
              else if (subiter->name == "name")
                {
                  /* The <name> element seems to give the contact ID, which
                   * we need to insert into the Persona's im-addresses property
                   * for the linking to work. */
                  string im_address = subiter->get_content ();
                  im_addresses.set (tp_protocol,
                      new ImFieldDetails (im_address));
                  im_address_string += "    %s\n".printf (im_address);
                }
            }
        }

      /* Don't bother if there's no alias and only one IM address */
      if (im_addresses.size < 2 &&
          (alias == null || alias.strip () == "" ||
           alias.strip () == im_address_string.strip ()))
        {
          stdout.printf (
              /* Translators: the parameter is the buddy's IM address. */
              _("Ignoring buddy with no alias and only one IM address:\n%s"),
              im_address_string);
          return null;
        }

      /* Create or update the relevant Persona */
      var details = new GLib.HashTable<string, Value?> (str_hash, str_equal);
      Value im_addresses_value = Value (typeof (MultiMap));
      im_addresses_value.set_object (im_addresses);
      details.insert ("im-addresses", im_addresses_value);

      Persona persona;
      try
        {
          persona =
              yield this.destination_store.add_persona_from_details (details);
        }
      catch (PersonaStoreError e)
        {
          /* Translators: the first parameter is an alias, the second is a set
           * of IM addresses each on a new line, and the third is an error
           * message. */
          stderr.printf (
              _("Failed to create new contact for buddy with alias ‘%s’ and IM addresses:\n%s\nError: %s\n"),
              alias, im_address_string, e.message);
          return null;
        }

      /* Set the Persona's details */
      if (alias != null && persona is AliasDetails)
        ((AliasDetails) persona).alias = alias;

      /* Print progress */
      stdout.printf (
          /* Translators: the first parameter is a persona identifier, the
           * second is an alias for the persona, and the third is a set of IM
           * addresses each on a new line. */
          _("Created contact ‘%s’ for buddy with alias ‘%s’ and IM addresses:\n%s"),
          persona.uid, alias, im_address_string);
      this.persona_count++;

      return persona;
    }

  private string? blist_protocol_to_tp_protocol (string blist_protocol)
    {
      string tp_protocol = blist_protocol;
      if (blist_protocol.has_prefix ("prpl-"))
        tp_protocol = blist_protocol.substring (5);

      /* Convert protocol names from Pidgin to Telepathy. Other protocol names
       * should be OK now that we've taken off the "prpl-" prefix. See:
       * http://telepathy.freedesktop.org/spec/Connection_Manager.html#Protocol
       * and http://developer.pidgin.im/wiki/prpl_id. */
      if (tp_protocol == "bonjour")
        tp_protocol = "local-xmpp";
      else if (tp_protocol == "novell")
        tp_protocol = "groupwise";
      else if (tp_protocol == "gg")
        tp_protocol = "gadugadu";
      else if (tp_protocol == "meanwhile")
        tp_protocol = "sametime";
      else if (tp_protocol == "simple")
        tp_protocol = "sip";

      return tp_protocol;
    }
}
