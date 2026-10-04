using System;
using System.IO;
using System.Text;
public static class CompactMotion {
 public static void Run(string source,string output,int stride,int normalBits) {
  byte[] input=File.ReadAllBytes(source);
  string baseHeader=File.ReadAllText(Path.Combine(Path.GetDirectoryName(source),"motion_data.h"));
  var frameMatch=System.Text.RegularExpressions.Regex.Match(baseHeader,@"#define MOTION_FRAMES\s+(\d+)");
  if(!frameMatch.Success) throw new InvalidDataException("Missing baked MOTION_FRAMES");
  int totalFrames=int.Parse(frameMatch.Groups[1].Value,System.Globalization.CultureInfo.InvariantCulture);
  if(input.Length!=((totalFrames+3)/4)*16384) throw new InvalidDataException("Unexpected baked motion size");
  var floorMatch=System.Text.RegularExpressions.Regex.Match(baseHeader,@"#define FLOOR_Y\s+(-?\d+)");
  if(!floorMatch.Success) throw new InvalidDataException("Missing baked FLOOR_Y");
  int floor=int.Parse(floorMatch.Groups[1].Value,System.Globalization.CultureInfo.InvariantCulture);
  int frames=(totalFrames+stride-1)/stride;
  int poseBytes=normalBits==0?3456:1080+216*(normalBits==16?6:3);
  int bytes=poseBytes+48;
  int perBank=16384/bytes;
  Directory.CreateDirectory(output);
  double errorSquared=0,maxError=0;long count=0;
  using(var w=new BinaryWriter(File.Create(Path.Combine(output,"motion-banks.bin")))) {
   for(int f=0;f<frames;f++) {
    if(f%perBank==0 && f!=0) while(w.BaseStream.Position%16384!=0)w.Write((byte)255);
    int original=f*stride;int offset=(original/4)*16384+(original%4)*3456;
    w.Write(input,offset,normalBits==0?3456:1080);
    if(normalBits!=0) for(int face=0;face<216;face++) for(int axis=0;axis<3;axis++) {
     short n=BitConverter.ToInt16(input,offset+1080+face*11+4+axis*2);
     if(normalBits==16)w.Write(n);
     else {
      int q=Math.Max(-64,Math.Min(64,(int)Math.Round(n/256.0)));
      w.Write(unchecked((byte)(sbyte)q));
      double e=q*256-n;errorSquared+=e*e;maxError=Math.Max(maxError,Math.Abs(e));count++;
     }
    }
    for(int group=0;group<4;group++) {
     int first=group==0?0:(group-1)*60,vertices=group==0?180:60;
     short[] bounds={32767,32767,32767,-32767,-32767,-32767};
     for(int vertex=first;vertex<first+vertices;vertex++) for(int axis=0;axis<3;axis++) {
      short v=BitConverter.ToInt16(input,offset+vertex*6+axis*2);
      bounds[axis]=Math.Min(bounds[axis],v);bounds[axis+3]=Math.Max(bounds[axis+3],v);
     }
     foreach(short v in bounds)w.Write(v);
    }
   }
   while(w.BaseStream.Position%16384!=0)w.Write((byte)255);
  }
  var h=new StringBuilder("#ifndef MOTION_DATA_H\n#define MOTION_DATA_H\n");
  h.AppendFormat("#define MOTION_FRAMES {6}\n#define SAMPLE_STRIDE {0}\n#define STORED_FRAMES {1}\n#define FRAME_BYTES {2}\n#define POSES_PER_BANK {3}\n#define NORMAL_BITS {4}\n#define VERTEX_BYTES 1080\n#define MOTION_BANK 2\n#define FLOOR_Y {5}\n",stride,frames,bytes,perBank,normalBits,floor,totalFrames);
  h.AppendFormat("#define POSE_BYTES {0}\n#define BOUNDS_OFFSET {0}\n",poseBytes);
  if(normalBits!=0) {
   h.Append("extern const unsigned char face_indices[648];\n#ifdef MOTION_DEFINE_TOPOLOGY\nconst unsigned char face_indices[648] = {\n");
   for(int f=0;f<216;f++){int p=1080+f*11;h.AppendFormat("{0},{1},{2},",input[p],input[p+1],input[p+2]);if(f%12==11)h.Append('\n');}
   h.Append("};\n#endif\n");
  }
  h.Append("#endif\n");File.WriteAllText(Path.Combine(output,"motion_data.h"),h.ToString());
  File.WriteAllText(Path.Combine(output,"codec-metrics.txt"),String.Format(System.Globalization.CultureInfo.InvariantCulture,"stored_frames={0}\nframe_bytes={1}\nposes_per_bank={2}\npayload_bytes={3}\nnormal_component_rms={4:F6}\nnormal_component_max={5}\n",frames,bytes,perBank,frames*bytes, count==0?0:Math.Sqrt(errorSquared/count),maxError));
 }
}
