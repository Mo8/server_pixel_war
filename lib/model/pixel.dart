import 'dart:ffi';

class Pixel{
  int x;
  int y;
  int color;
  Pixel(this.x, this.y,this.color);

  Map<String,int> toJson(){
    return {
      "x":x,
      "y":y,
      "color":color
    };
  }

  factory Pixel.fromJson(Map<String,dynamic> json){
    final color =  int.parse(json["color"].toString());

    return Pixel(json["x"], json["y"],color);
  }
}