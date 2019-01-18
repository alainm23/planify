/*
 * Copyright (C) 2011 Collabora Ltd.
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
using Folks;

/**
 * An object cache class which implements caching of sets of
 * {@link Tpf.Persona}s from a given {@link Tpf.PersonaStore}.
 *
 * Each {@link Tpf.Persona} is stored as a serialised {@link Variant} which is
 * a tuple containing the following fields:
 *  # UID (``s``)
 *  # IID (``s``)
 *  # IM address (``s``)
 *  # Protocol (``s``)
 *  # Set of group names (``as``)
 *  # Favourite? (``b``)
 *  # Alias (``s``)
 *  # In contact list? (``b``)
 *  # Avatar file URI (``s``)
 *  # Birthday date as a Unix timestamp (``s``)
 *  # Set of e-mail addresses and parameters (``a(sa(ss))``)
 *  # Full name (``s``)
 *
 * @since 0.6.0
 */
internal class Tpf.PersonaStoreCache : Folks.ObjectCache<Tpf.Persona>
{
  /**
   * The {@link Tpf.PersonaStore} associated with this cache.
   *
   * @since 0.6.6
   */
  public weak PersonaStore store { get; construct; }

  /* Version number of the variant type returned by
   * get_serialised_object_type(). This must be modified whenever that variant
   * type or its semantics are changed, since that would necessitate a cache
   * refresh. */
  private const uint8 _FILE_FORMAT_VERSION = 2;

  internal PersonaStoreCache (PersonaStore store)
    {
      Object (type_id: "tpf-persona-stores",
              id: store.id,
              store: store);
    }

  protected override VariantType? get_serialised_object_type (
      uint8 object_version)
    {
      // Maximum version?
      if (object_version == uint8.MAX)
        {
          object_version = PersonaStoreCache._FILE_FORMAT_VERSION;
        }

      if (object_version == 1)
        {
          return new VariantType.tuple ({
            VariantType.STRING, // UID
            VariantType.STRING, // IID
            VariantType.STRING, // ID
            VariantType.STRING, // Protocol
            new VariantType.array (VariantType.STRING), // Groups
            VariantType.BOOLEAN, // Favourite?
            VariantType.STRING, // Alias
            VariantType.BOOLEAN, // In contact list?
            VariantType.BOOLEAN, // Is user?
            new VariantType.maybe (VariantType.STRING) // Avatar
          });
        }
      else if (object_version == 2 || object_version == uint8.MAX)
        {
          return new VariantType.tuple ({
            VariantType.STRING, // UID
            VariantType.STRING, // IID
            VariantType.STRING, // ID
            VariantType.STRING, // Protocol
            new VariantType.array (VariantType.STRING), // Groups
            VariantType.BOOLEAN, // Favourite?
            VariantType.STRING, // Alias
            VariantType.BOOLEAN, // In contact list?
            VariantType.BOOLEAN, // Is user?
            new VariantType.maybe (VariantType.STRING), // Avatar
            new VariantType.maybe (VariantType.INT64), // Birthday
            VariantType.STRING, // Full name
            new VariantType.array (new VariantType.tuple ({
              VariantType.STRING, // E-mail address
              new VariantType.array (new VariantType.tuple ({
                VariantType.STRING, // Key
                VariantType.STRING // Value
              })) // Parameters
            })), // E-mail addresses
            new VariantType.array (new VariantType.tuple ({
              VariantType.STRING, // Phone number
              new VariantType.array (new VariantType.tuple ({
                VariantType.STRING, // Key
                VariantType.STRING // Value
              })) // Parameters
            })), // Phone numbers
            new VariantType.array (new VariantType.tuple ({
              VariantType.STRING, // URL
              new VariantType.array (new VariantType.tuple ({
                VariantType.STRING, // Key
                VariantType.STRING // Value
              })) // Parameters
            })) // URLs
          });
        }

      // Unsupported version
      return null;
    }

  protected override uint8 get_serialised_object_version ()
    {
      return PersonaStoreCache._FILE_FORMAT_VERSION;
    }

  private Variant[] serialise_abstract_field_details (
      Set<AbstractFieldDetails<string>> field_details_set)
    {
      Variant[] output_variants = new Variant[field_details_set.size];

      uint i = 0;
      foreach (var afd in field_details_set)
        {
          Variant[] parameters = new Variant[afd.parameters.size];

          uint f = 0;

          var iter = afd.parameters.map_iterator ();

          while (iter.next ())
            parameters[f++] = new Variant.tuple ({
              new Variant.string (iter.get_key ()),
              new Variant.string (iter.get_value ())
            });

          output_variants[i++] = new Variant.tuple ({
            afd.value, // Variant value (e.g. e-mail address)
            new Variant.array (new VariantType.tuple ({
              VariantType.STRING, // Key
              VariantType.STRING // Value
            }), parameters)
          });
        }

      return output_variants;
    }

  protected override Variant serialise_object (Tpf.Persona persona)
    {
      // Sort out the groups
      Variant[] groups = new Variant[persona.groups.size];

      uint i = 0;
      foreach (var group in persona.groups)
        {
          groups[i++] = new Variant.string (group);
        }

      // Sort out the IM addresses (there's guaranteed to only be one)
      string? im_protocol = null;

      var iter = persona.im_addresses.map_iterator ();

      if (iter.next ())
        im_protocol = iter.get_key ();

      // Avatar
      var avatar_file = (persona.avatar != null && persona.avatar is FileIcon) ?
          (persona.avatar as FileIcon).get_file () : null;
      var avatar_variant = (avatar_file != null) ?
          new Variant.string (avatar_file.get_uri ()) : null;

      // Birthday
      var birthday_variant = (persona.birthday != null) ?
          new Variant.int64 (persona.birthday.to_unix ()) : null;

      // Sort out the e-mail addresses, phone numbers and URLs
      var email_addresses =
          this.serialise_abstract_field_details (persona.email_addresses);
      var phone_numbers =
          this.serialise_abstract_field_details (persona.phone_numbers);
      var urls = this.serialise_abstract_field_details (persona.urls);

      // Serialise the persona
      return new Variant.tuple ({
        new Variant.string (persona.uid),
        new Variant.string (persona.iid),
        new Variant.string (persona.display_id),
        new Variant.string (im_protocol),
        new Variant.array (VariantType.STRING, groups),
        new Variant.boolean (persona.is_favourite),
        new Variant.string (persona.alias),
        new Variant.boolean (persona.is_in_contact_list),
        new Variant.boolean (persona.is_user),
        new Variant.maybe (VariantType.STRING, avatar_variant),
        new Variant.maybe (VariantType.INT64, birthday_variant),
        new Variant.string (persona.full_name),
        new Variant.array (new VariantType.tuple ({
          VariantType.STRING, // E-mail address
          new VariantType.array (new VariantType.tuple ({
            VariantType.STRING, // Key
            VariantType.STRING // Value
          })) // Parameters
        }), email_addresses),
        new Variant.array (new VariantType.tuple ({
          VariantType.STRING, // Phone number
          new VariantType.array (new VariantType.tuple ({
            VariantType.STRING, // Key
            VariantType.STRING // Value
          })) // Parameters
        }), phone_numbers),
        new Variant.array (new VariantType.tuple ({
          VariantType.STRING, // URL
          new VariantType.array (new VariantType.tuple ({
            VariantType.STRING, // Key
            VariantType.STRING // Value
          })) // Parameters
        }), urls)
      });
    }

  private delegate void AfdDeserialisationCallback (string val,
      HashMultiMap<string, string> parameters);

  private void deserialise_abstract_field_details (Variant input_variants,
      AfdDeserialisationCallback cb)
    {
      for (uint i = 0; i < input_variants.n_children (); i++)
        {
          var input_variant = input_variants.get_child_value (i);

          var val = input_variant.get_child_value (0).get_string ();

          var parameters = new HashMultiMap<string, string> ();
          var params_variants = input_variant.get_child_value (1);
          for (uint f = 0; f < params_variants.n_children (); f++)
            {
              var params_variant = params_variants.get_child_value (f);

              parameters.set (
                  params_variant.get_child_value (0).get_string (),
                  params_variant.get_child_value (1).get_string ());
            }

          // Output
          cb (val, parameters);
        }
    }

  protected override Tpf.Persona deserialise_object (Variant variant,
      uint8 object_version)
    {
      // Deserialise the persona
      var uid = variant.get_child_value (0).get_string ();
      var iid = variant.get_child_value (1).get_string ();
      var display_id = variant.get_child_value (2).get_string ();
      var im_protocol = variant.get_child_value (3).get_string ();
      var groups = variant.get_child_value (4);
      var is_favourite = variant.get_child_value (5).get_boolean ();
      var alias = variant.get_child_value (6).get_string ();
      var is_in_contact_list = variant.get_child_value (7).get_boolean ();
      var is_user = variant.get_child_value (8).get_boolean ();
      var avatar_variant = variant.get_child_value (9).get_maybe ();

      // Deserialise the groups
      var group_set = new SmallSet<string> ();
      for (uint i = 0; i < groups.n_children (); i++)
        {
          group_set.add (groups.get_child_value (i).get_string ());
        }

      // Deserialise the avatar
      var avatar = (avatar_variant != null) ?
          new FileIcon (File.new_for_uri (avatar_variant.get_string ())) :
          null;

      // Deserialise the birthday
      DateTime? birthday = null;
      if (object_version == 2)
        {
          var birthday_variant = variant.get_child_value (10).get_maybe ();
          if (birthday_variant != null)
            {
              /* Note: This may return a null value if the stored value is
               * invalid (e.g. out of range). */
              birthday =
                  new DateTime.from_unix_utc (birthday_variant.get_int64 ());
            }
        }

      var full_name = "";
      if (object_version == 2)
        {
          full_name = variant.get_child_value (11).get_string();
        }

      var email_address_set = new SmallSet<EmailFieldDetails> (
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);
      var phone_number_set = new SmallSet<PhoneFieldDetails> (
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);
      var url_set = new SmallSet<UrlFieldDetails> (
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);

      if (object_version == 2)
        {
          /* Make sure that the extracted value is not empty as caches created
           * before bgo#675144 was fixed may have stored empty values. */
          this.deserialise_abstract_field_details (variant.get_child_value (12),
              (v, p) =>
                {
                  if (v != "")
                    {
                      email_address_set.add (new EmailFieldDetails (v, p));
                    }
                });
          this.deserialise_abstract_field_details (variant.get_child_value (13),
              (v, p) =>
                {
                  if (v != "")
                    {
                      phone_number_set.add (new PhoneFieldDetails (v, p));
                    }
                });
          this.deserialise_abstract_field_details (variant.get_child_value (14),
              (v, p) =>
                {
                  if (v != "")
                    {
                      url_set.add (new UrlFieldDetails (v, p));
                    }
                });
        }

      return new Tpf.Persona.from_cache (this._store, uid, iid, display_id,
          im_protocol, group_set, is_favourite, alias, is_in_contact_list,
          is_user, avatar, birthday, full_name, email_address_set,
          phone_number_set, url_set);
    }
}

/* vim: filetype=vala textwidth=80 tabstop=2 expandtab: */
