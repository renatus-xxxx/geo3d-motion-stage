using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Globalization;

// Development-time BVH evaluator. The MSX does not parse BVH or use floats.
public class BvhBake {
    struct V {
        public double x, y, z;
        public V(double a, double b, double c) {
            x = a;
            y = b;
            z = c;
        }
        public static V operator +(V a, V b) {
            return new V(a.x + b.x, a.y + b.y, a.z + b.z);
        }
        public static V operator -(V a, V b) {
            return new V(a.x - b.x, a.y - b.y, a.z - b.z);
        }
        public static V operator *(V a, double s) {
            return new V(a.x * s, a.y * s, a.z * s);
        }
        public double Dot(V b) {
            return x * b.x + y * b.y + z * b.z;
        }
        public V Cross(V b) {
            return new V(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);
        }
        public V Unit() {
            double n = Math.Sqrt(Dot(this));
            return n < 1e-9 ? new V(1, 0, 0) : this * (1 / n);
        }
    }
    class Joint {
        public string name;
        public int parent;
        public V offset, site;
        public List<int> channels = new List<int>();
        public List<string> types = new List<string>();
    }
    class Clip {
        public List<Joint> joints = new List<Joint>();
        public string[] tokens;
        public int pos, channels, frames;
        public double step;
        public double[][] motion;
        string Next() {
            return tokens[pos++];
        }
        void Need(string s) {
            if (Next() != s)
                throw new Exception("Expected " + s);
        }
        double Number() {
            return double.Parse(Next(), CultureInfo.InvariantCulture);
        }
        V Vector() {
            return new V(Number(), Number(), Number());
        }
        void ParseJoint(int parent) {
            Joint j = new Joint();
            j.name = Next();
            j.parent = parent;
            int index = joints.Count;
            joints.Add(j);
            Need("{");
            while (true) {
                string t = Next();
                if (t == "}")
                    break;
                if (t == "OFFSET")
                    j.offset = Vector();
                else if (t == "CHANNELS") {
                    int n = int.Parse(Next());
                    for (int k = 0; k < n; k++) {
                        j.channels.Add(channels++);
                        j.types.Add(Next());
                    }
                } else if (t == "JOINT")
                    ParseJoint(index);
                else if (t == "End") {
                    Need("Site");
                    Need("{");
                    Need("OFFSET");
                    j.site = Vector();
                    Need("}");
                } else
                    throw new Exception("Unknown hierarchy token " + t);
            }
        }
        public Clip(string file) {
            string source = File.ReadAllText(file);
            if (string.IsNullOrWhiteSpace(source))
                throw new Exception("Empty BVH input: " + Path.GetFileName(file));
            tokens = Tokens(source);
            Need("HIERARCHY");
            Need("ROOT");
            ParseJoint(-1);
            Need("MOTION");
            Need("Frames:");
            frames = int.Parse(Next());
            Need("Frame");
            Need("Time:");
            step = Number();
            motion = new double [frames][];
            for (int f = 0; f < frames; f++) {
                motion[f] = new double[channels];
                for (int c = 0; c < channels; c++)
                    motion[f][c] = Number();
            }
            if (pos != tokens.Length)
                throw new Exception("Trailing BVH data");
        }
        static string[] Tokens(string s) {
            MatchCollection m = Regex.Matches(s, @"[^\s{}]+|[{}]");
            string[] a = new string[m.Count];
            for (int i = 0; i < a.Length; i++)
                a[i] = m[i].Value;
            return a;
        }
        public int Find(string s) {
            int n = joints.FindIndex(j => j.name == s);
            if (n < 0)
                throw new Exception("Missing joint " + s);
            return n;
        }
    }
    static double[] Identity() {
        return new double[] { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
    }
    static double[] Mul(double[] a, double[] b) {
        double[] r = new double[16];
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                for (int k = 0; k < 4; k++)
                    r[i * 4 + j] += a[i * 4 + k] * b[k * 4 + j];
        return r;
    }
    static V Point(double[] m, V p) {
        return new V(m[0] * p.x + m[1] * p.y + m[2] * p.z + m[3],
                     m[4] * p.x + m[5] * p.y + m[6] * p.z + m[7],
                     m[8] * p.x + m[9] * p.y + m[10] * p.z + m[11]);
    }
    static double[] Rotate(string type, double angle) {
        double[] r = Identity();
        double c = Math.Cos(angle * Math.PI / 180), s = Math.Sin(angle * Math.PI / 180);
        if (type == "Xrotation") {
            r[5] = c;
            r[6] = -s;
            r[9] = s;
            r[10] = c;
        }
        if (type == "Yrotation") {
            r[0] = c;
            r[2] = s;
            r[8] = -s;
            r[10] = c;
        }
        if (type == "Zrotation") {
            r[0] = c;
            r[1] = -s;
            r[4] = s;
            r[5] = c;
        }
        return r;
    }
    class Face {
        public int a, b, c;
        public V n;
    }
    class Pose {
        public List<V> vertices = new List<V>();
        public List<Face> faces = new List<Face>();
    }
    static string[,] Bones = { { "Hips", "Chest3" },
                               { "Chest3", "Neck" },
                               { "Head", "@site" },
                               { "LeftHip", "RightHip" },
                               { "LeftShoulder", "LeftElbow" },
                               { "LeftElbow", "LeftWrist" },
                               { "RightShoulder", "RightElbow" },
                               { "RightElbow", "RightWrist" },
                               { "LeftHip", "LeftKnee" },
                               { "LeftKnee", "LeftAnkle" },
                               { "RightHip", "RightKnee" },
                               { "RightKnee", "RightAnkle" } };
    static void Body(Pose p, Clip clip, int frame) {
        double[][] world = new double [clip.joints.Count][];
        for (int i = 0; i < world.Length; i++) {
            Joint j = clip.joints[i];
            double[] local = Identity();
            V t = j.offset;
            for (int k = 0; k < j.channels.Count; k++) {
                double v = clip.motion[frame][j.channels[k]];
                string type = j.types[k];
                if (type == "Xposition")
                    t.x += v;
                if (type == "Yposition")
                    t.y += v;
                if (type == "Zposition")
                    t.z += v;
            }
            local[3] = t.x;
            local[7] = t.y;
            local[11] = t.z;
            // BVH declares the Euler order; do not assume XYZ.
            for (int k = 0; k < j.channels.Count; k++)
                if (j.types[k].EndsWith("rotation"))
                    local = Mul(local, Rotate(j.types[k], clip.motion[frame][j.channels[k]]));
            world[i] = j.parent < 0 ? local : Mul(world[j.parent], local);
        }
        for (int bone = 0; bone < 12; bone++) {
            int j = clip.Find(Bones[bone, 0]);
            V a = Point(world[j], new V(0, 0, 0)) * 2;
            V b = (Bones[bone, 1] == "@site"
                       ? Point(world[j], clip.joints[j].site)
                       : Point(world[clip.Find(Bones[bone, 1])], new V(0, 0, 0))) *
                  2;
            V axis = (b - a).Unit(), center = (a + b) * .5;
            V u = new V(world[j][0], world[j][4], world[j][8]);
            u = u - axis * u.Dot(axis);
            if (u.Dot(u) < .0001)
                u = axis.Cross(new V(0, 0, 1));
            u = u.Unit();
            V v = axis.Cross(u).Unit();
            double radius = bone < 4 ? 12 : 5.5;
            if (bone == 2)
                radius = 14;
            int start = p.vertices.Count;
            p.vertices.Add(a);
            p.vertices.Add(b);
            for (int k = 0; k < 3; k++) {
                double angle = k * 2 * Math.PI / 3;
                p.vertices.Add(center + (u * Math.Cos(angle) + v * Math.Sin(angle)) * radius);
            }
            for (int k = 0; k < 3; k++)
                for (int end = 0; end < 2; end++) {
                    int ia = start + end, ib = start + 2 + k, ic = start + 2 + (k + 1) % 3;
                    V n = (p.vertices[ib] - p.vertices[ia]).Cross(p.vertices[ic] - p.vertices[ia]);
                    if (n.Dot((p.vertices[ia] + p.vertices[ib] + p.vertices[ic]) * (1.0 / 3) -
                              center) < 0) {
                        int swap = ib;
                        ib = ic;
                        ic = swap;
                        n = n * (-1);
                    }
                    p.faces.Add(new Face { a = ia, b = ib, c = ic, n = n.Unit() });
                }
        }
    }
    static short Quant(double x) {
        if (x < short.MinValue || x > short.MaxValue)
            throw new Exception("Coordinate overflow");
        return (short)Math.Round(x);
    }
    public static void Run(string assets, string build) {
        string[] names = { "aachan", "kashiyuka", "nocchi" };
        Clip[] clips = new Clip[3];
        for (int i = 0; i < 3; i++)
            clips[i] = new Clip(Path.Combine(assets, names[i] + ".bvh"));
        foreach (Clip c in clips)
            if (c.frames != 2820 || Math.Abs(c.step - .025) > 1e-6 || c.joints.Count != 23)
                throw new Exception("Unexpected BVH layout");
        int frames = 1410;
        Pose[] poses = new Pose[frames];
        V lo = new V(1e9, 1e9, 1e9), hi = new V(-1e9, -1e9, -1e9);
        for (int f = 0; f < frames; f++) {
            Pose p = poses[f] = new Pose();
            for (int actor = 0; actor < 3; actor++)
                Body(p, clips[actor], f * 2);
            foreach (V q in p.vertices) {
                lo.x = Math.Min(lo.x, q.x);
                lo.y = Math.Min(lo.y, q.y);
                lo.z = Math.Min(lo.z, q.z);
                hi.x = Math.Max(hi.x, q.x);
                hi.y = Math.Max(hi.y, q.y);
                hi.z = Math.Max(hi.z, q.z);
            }
        }
        V center = (lo + hi) * .5;
        int floor = (int)Math.Round(-center.y);
        Directory.CreateDirectory(build);
        using (BinaryWriter w =
                   new BinaryWriter(File.Create(Path.Combine(build, "motion-banks.bin")))) {
            for (int f = 0; f < frames; f++) {
                if (f % 4 == 0 && f != 0)
                    while (w.BaseStream.Position % 16384 != 0)
                        w.Write((byte)255);
                foreach (V q in poses[f].vertices) {
                    V r = q - center;
                    w.Write(Quant(r.x));
                    w.Write(Quant(r.y));
                    w.Write(Quant(r.z));
                }
                foreach (Face face in poses[f].faces) {
                    w.Write((byte)face.a);
                    w.Write((byte)face.b);
                    w.Write((byte)face.c);
                    w.Write((byte)face.c);
                    w.Write(Quant(face.n.x * 16384));
                    w.Write(Quant(face.n.y * 16384));
                    w.Write(Quant(face.n.z * 16384));
                    w.Write((byte)1);
                }
            }
            while (w.BaseStream.Position % 16384 != 0)
                w.Write((byte)255);
            if (w.BaseStream.Length + 32768 > 8 * 1024 * 1024)
                throw new Exception("ASCII16-X 8 MB limit exceeded");
        }
        string header =
            "#ifndef MOTION_DATA_H\n#define MOTION_DATA_H\n#define MOTION_FRAMES 1410\n#define " +
            "FRAME_BYTES 3456\n#define VERTEX_BYTES 1080\n#define MOTION_BANK 2\n#define FLOOR_Y " +
            floor + "\n";
        int[] bounds = {
            (int)Math.Floor(lo.x - center.x) - 2,   (int)Math.Floor(lo.y - center.y) - 2,
            (int)Math.Floor(lo.z - center.z) - 2,   (int)Math.Ceiling(hi.x - center.x) + 2,
            (int)Math.Ceiling(hi.y - center.y) + 2, (int)Math.Ceiling(hi.z - center.z) + 2
        };
        header += "/* Sequence bounds: " + string.Join(",", bounds) + " */\n#endif\n";
        File.WriteAllText(Path.Combine(build, "motion_data.h"), header);
        File.WriteAllText(
            Path.Combine(build, "bake-report.txt"),
            "3 actors; 23 joints each; BVH 2820 frames at 40 Hz.\nBaked 1410 poses at 20 Hz; " +
            "70.5 s.\n180 vertices, 216 faces, 3456 bytes/pose, 4 poses/16 KB bank.\nBounds: " +
                string.Join(",", bounds) + "\nFloor: " + floor + "\nData bytes: " +
                new FileInfo(Path.Combine(build, "motion-banks.bin")).Length + "\n");
    }
}
