/* fuse.vapi
 *
 * Copyright (C) 2009  Codethink Ltd.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	John Carr <john.carr@unrouted.co.uk>
 */

[CCode (cprefix = "fuse_", cheader_filename = "fuse/fuse.h")]
namespace Fuse {
	[CCode (cname = "struct fuse_file_info", has_type_id = false)]
	public struct FileInfo {
		public int flags;
		public ulong fh_old;
		public int writepage;
		public uint direct_io;
		public uint keep_cache;
		public uint flush;
		public uint padding;
		public uint64 fh;
		public uint64 lock_owner;
	}

	[CCode (cname = "struct fuse", has_type_id = false)]
	public struct Fuse {
	}

	[CCode (cname = "struct fuse_context", has_type_id = false)]
	public struct Context {
		Fuse fuse;
		Posix.uid_t uid;
		Posix.gid_t gid;
		/*Posix.pid_t pid;*/
		void *private_data;
	}

	[CCode (cname = "fuse_fill_dir_t", has_target = false)]
	public delegate int FillDir (void* buf, string name, Posix.Stat? st, Posix.off_t offset);

	[CCode (has_target = false)]
	public delegate int GetAttr (string path, Posix.Stat* st);
	[CCode (has_target = false)]
	public delegate int Access (string path, int mask);
	[CCode (has_target = false)]
	public delegate int ReadLink (string path, char* buf, size_t size);
	[CCode (has_target = false)]
	public delegate int ReadDir (string path, void* buf, FillDir filler, Posix.off_t offset, ref FileInfo fi);
	[CCode (has_target = false)]
	public delegate int MkNod (string path, Posix.mode_t mode, Posix.dev_t rdev);
	[CCode (has_target = false)]
	public delegate int MkDir (string path, Posix.mode_t mode);
	[CCode (has_target = false)]
	public delegate int Unlink (string path);
	[CCode (has_target = false)]
	public delegate int RmDir (string path);
	[CCode (has_target = false)]
	public delegate int Symlink (string from, string to);
	[CCode (has_target = false)]
	public delegate int Rename (string from, string to);
	[CCode (has_target = false)]
	public delegate int Link (string from, string to);
	[CCode (has_target = false)]
	public delegate int Chmod (string path, Posix.mode_t mode);
	[CCode (has_target = false)]
	public delegate int Chown (string path, Posix.uid_t uid, Posix.gid_t gid);
	[CCode (has_target = false)]
	public delegate int Truncate (string path, Posix.off_t size);
	[CCode (has_target = false)]
	public delegate int Utimens (string path, Posix.timespec[] ts);
	[CCode (has_target = false)]
	public delegate int Create(string path, Posix.mode_t mode, ref FileInfo fi);
	[CCode (has_target = false)]
	public delegate int Open (string path, ref FileInfo fi);
	[CCode (has_target = false)]
	public delegate int Read (string path, char* buf, size_t size, Posix.off_t offset, ref FileInfo fi);
	[CCode (has_target = false)]
	public delegate int Write (string path, char* buf, size_t size, Posix.off_t offset, ref FileInfo fi);
	[CCode (has_target = false)]
	public delegate int StatFs (string path, Posix.statvfs *stbuf);
	[CCode (has_target = false)]
	public delegate int Release (string path, ref FileInfo fi);
	[CCode (has_target = false)]
	public delegate int Fsync (string path, int isdatasync, ref FileInfo fi);

	[CCode (has_target = false)]
	public delegate int SetXAttr (string path, string name, char* value, size_t size, int flags);
	[CCode (has_target = false)]
	public delegate int GetXAttr (string path, string name, char* value, size_t size);
	[CCode (has_target = false)]
	public delegate int ListXAttr (string path, char* list, size_t size);
	[CCode (has_target = false)]
	public delegate int RemoveXAttr (string path, string name);

	[CCode (cname = "struct fuse_operations", has_type_id = false)]
	public struct Operations {
		public GetAttr getattr;
		public Access access;
		public ReadLink readlink;
		public ReadDir readdir;
		public MkNod mknod;
		public MkDir mkdir;
		public Symlink symlink;
		public Unlink unlink;
		public RmDir rmdir;
		public Rename rename;
		public Link link;
		public Chmod chmod;
		public Chown chown;
		public Truncate truncate;
		public Utimens utimens;
		public Create create;
		public Open open;
		public Read read;
		public Write write;
		public StatFs statfs;
		public Release release;
		public Fsync fsync;
		public SetXAttr setxattr;
		public GetXAttr getxattr;
		public ListXAttr listxattr;
		public RemoveXAttr removexattr;
	}

	public int main ([CCode (array_length_pos = 0.9)] string[] args, Operations oper, void *user_data);
	public Context get_context ();
}
