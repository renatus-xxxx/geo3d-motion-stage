using System;
using System.IO;
public static class VerifyMotion {
 public static string Run(string baseline,string packed,int stride,int bits) {
  byte[] source=File.ReadAllBytes(baseline),data=File.ReadAllBytes(packed);
  int size=(bits==0?3456:2376)+48,perBank=16384/size,poses=(1410+stride-1)/stride;
  long checkedVertices=0,checkedNormals=0,checkedBounds=0;
  for(int frame=0;frame<poses;frame++) {
   int original=frame*stride,s=(original/4)*16384+(original%4)*3456;
   int d=(frame/perBank)*16384+(frame%perBank)*size;
   for(int i=0;i<1080;i++) if(source[s+i]!=data[d+i])throw new Exception("Vertex mismatch");
   checkedVertices+=180;
   for(int face=0;face<216;face++) {
    int sf=s+1080+face*11;
    if(source[sf+2]!=source[sf+3] || source[sf+10]!=1)throw new Exception("Unsupported topology/color");
    for(int i=0;i<3;i++)if(source[sf+i]!=source[1080+face*11+i])throw new Exception("Topology changed");
    int df=d+1080+(bits==0?face*11+4:face*6);
    for(int i=0;i<6;i++)if(source[sf+4+i]!=data[df+i])throw new Exception("Normal mismatch");
    if(bits==0)for(int i=0;i<11;i++)if(source[sf+i]!=data[d+1080+face*11+i])throw new Exception("Face mismatch");
    checkedNormals++;
   }
   for(int group=0;group<4;group++) {
    int first=group==0?0:(group-1)*60,count=group==0?180:60;
    int[] bounds={32767,32767,32767,-32767,-32767,-32767};
    for(int vertex=first;vertex<first+count;vertex++)for(int axis=0;axis<3;axis++) {
     int value=BitConverter.ToInt16(source,s+vertex*6+axis*2);
     bounds[axis]=Math.Min(bounds[axis],value);bounds[axis+3]=Math.Max(bounds[axis+3],value);
    }
    for(int axis=0;axis<6;axis++)if(bounds[axis]!=BitConverter.ToInt16(data,d+size-48+group*12+axis*2))throw new Exception("Baked bounds differ from vertex scan");
    checkedBounds++;
   }
  }
  return String.Format("PASS poses={0} vertices={1} normals={2} bounds={3} data_banks={4}",poses,checkedVertices,checkedNormals,checkedBounds,data.Length/16384);
 }
}
