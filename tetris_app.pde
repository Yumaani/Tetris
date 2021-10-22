import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

Minim minim;
AudioPlayer linedelete;
AudioPlayer tetris;
AudioPlayer bgm;
AudioPlayer holdm;
AudioPlayer rotate;
AudioPlayer gameover;
AudioPlayer move;
AudioPlayer stop;

int [][] grid = new int [16][24];//テトリスのマス
color [][]grid_color = new color[16][24];//マス色
int time=0;
color c;
int delete_count=0;
int speed=48;//落下にかかるフレーム数

int score=0;
int line_count=0;
int [] next = new int [7];//テトリミノを決める
int [] rand = new int [7];
int rand_count;
int [][] nextshape= new int [4][4];
color nextc;
int level=0;
int level_count=0;
int stop_time=20;

//ホールドに関する変数
int hold;
boolean hold_change=true;
boolean hold_first=true;
int [][] holdshape=new int [4][4];
color holdc;

int down_count;

Tetrimino obj1;

void setup() {
  background(0);
  size(960, 640);
  for (int i=0; i<16; i++) {
    for (int j=0; j<22; j++) {
      if (i<3||i>12||j>=21) {//ゲーム画面外に当たり判定をつける
        grid[i][j]=1;
      } else {
        grid[i][j]=0;
      }
    }
  }
  shuffleSeven();
  for (int i=0; i<7; i++) {//最初のテトリミノを決める
    next[i]=rand[i];
  }
  shuffleSeven();
  obj1=new Tetrimino();

  minim = new Minim(this);
  linedelete = minim.loadFile("line.mp3");
  tetris = minim.loadFile("tetris.mp3");
  bgm=minim.loadFile("bgm.mp3");
  holdm = minim.loadFile("holdm.mp3");
  rotate = minim.loadFile("rotate.mp3");
  rotate.setGain(-5);
  gameover=minim.loadFile("gameover.mp3");
  gameover.setGain(-5);
  move=minim.loadFile("move.mp3");
  move.setGain(-10);
  stop=minim.loadFile("stop.mp3");

  bgm.loop();
}

void draw() {
  stageDraw();
  obj1.showTetris();
  timeCount();
  deleteTetris();
}

void keyPressed() {
  obj1.keyPressed();
}

void stageDraw() {//ゲーム画面の描画
  background(0);
  noFill();
  strokeWeight(6);
  stroke(155);
  line(317, 0, 317, 640);
  line(643, 0, 643, 640);
  textSize(30);
  fill(155);
  text("SCORE : "+score, 20, 40);
  text("LEVEL : "+level, 20, 80);
  if (level_count>1) {
    text("LINES : "+level_count, 20, 120);
  } else {
    text("LINE  : "+level_count, 20, 120);
  }
  nextShow();
  holdShow();
  for (int i=0; i<20; i++) {//マスの描画
    strokeWeight(1);
    stroke(100);
    if (i<10) {
      line(i*32+320, 0, i*32+320, 640);
    }
    line(320, 32*i, 640, 32*i);
  }
  strokeWeight(1);
  stroke(0);
  for (int i=3; i<13; i++) {//落ち切ったテトリミノの描画
    for (int j=1; j<21; j++) {
      if (grid[i][j]==1) {
        fill(grid_color[i][j]);
        rect((i-3)*32+320, (j-1)*32, 32, 32);
      }
    }
  }
}
void holdShow() {//ホールドテトリミノ周りの描画
  noFill();
  stroke(155);
  strokeWeight(3);
  rect(195, 38, 105, 76);
  fill(155);
  textSize(25);
  text("HOLD", 217, 30);
  for (int ii=0; ii<4; ii++) {//配列初期化
    for (int jj=0; jj<4; jj++) {
      holdshape[ii][jj]=0;
    }
  }
  //テトリミノの形・色
  if (hold==1) {//I水色
    holdshape[0][1]=1;
    holdshape[1][1]=1;
    holdshape[2][1]=1;
    holdshape[3][1]=1;
    holdc=color(0, 255, 255);
  }
  if (hold==2) {//O黄色
    holdshape[1][1]=1;
    holdshape[1][2]=1;
    holdshape[2][1]=1;
    holdshape[2][2]=1;
    holdc=color(255, 255, 0);
  }
  if (hold==3) {//T紫
    holdshape[1][1]=1;
    holdshape[2][1]=1;
    holdshape[3][1]=1;
    holdshape[2][2]=1;
    holdc=color(255, 0, 255);
  }
  if (hold==4) {//J青
    holdshape[1][1]=1;
    holdshape[2][1]=1;
    holdshape[3][1]=1;
    holdshape[3][2]=1;
    holdc=color(0, 0, 255);
  }
  if (hold==5) {//Lオレンジ
    holdshape[1][1]=1;
    holdshape[2][1]=1;
    holdshape[3][1]=1;
    holdshape[1][2]=1;
    holdc=color(255, 155, 0);
  }
  if (hold==6) {//S緑
    holdshape[1][2]=1;
    holdshape[2][1]=1;
    holdshape[2][2]=1;
    holdshape[3][1]=1;
    holdc=color(0, 255, 0);
  }
  if (hold==7) {//Z赤
    holdshape[1][1]=1;
    holdshape[2][1]=1;
    holdshape[2][2]=1;
    holdshape[3][2]=1;
    holdc=color(255, 0, 0);
  }
  for (int ii=0; ii<4; ii++) {//テトリミノ描画
    for (int jj=0; jj<4; jj++) {
      if (holdshape[ii][jj]==1) {
        strokeWeight(1);
        stroke(0);
        fill(holdc);
        rect(20*ii+200, 20*jj+35, 20, 20);
      }
    }
  }
}



void nextShow() {//NEXTのテトリミノの描画周り
  noFill();
  stroke(155);
  strokeWeight(3);
  rect(660, 40, 105, 76);
  rect(660, 130, 105, 400);
  fill(155);
  textSize(25);
  text("NEXT", 685, 30);
  for (int i=1; i<7; i++) {//配列初期化
    for (int ii=0; ii<4; ii++) {
      for (int jj=0; jj<4; jj++) {
        nextshape[ii][jj]=0;
      }
    }
    //テトリミノの形・色
    if (next[i]==1) {//I水色
      nextshape[0][1]=1;
      nextshape[1][1]=1;
      nextshape[2][1]=1;
      nextshape[3][1]=1;
      nextc=color(0, 255, 255);
    }
    if (next[i]==2) {//O黄色
      nextshape[1][1]=1;
      nextshape[1][2]=1;
      nextshape[2][1]=1;
      nextshape[2][2]=1;
      nextc=color(255, 255, 0);
    }
    if (next[i]==3) {//T紫
      nextshape[1][1]=1;
      nextshape[2][1]=1;
      nextshape[3][1]=1;
      nextshape[2][2]=1;
      nextc=color(255, 0, 255);
    }
    if (next[i]==4) {//J青
      nextshape[1][1]=1;
      nextshape[2][1]=1;
      nextshape[3][1]=1;
      nextshape[3][2]=1;
      nextc=color(0, 0, 255);
    }
    if (next[i]==5) {//Lオレンジ
      nextshape[1][1]=1;
      nextshape[2][1]=1;
      nextshape[3][1]=1;
      nextshape[1][2]=1;
      nextc=color(255, 155, 0);
    }
    if (next[i]==6) {//S緑
      nextshape[1][2]=1;
      nextshape[2][1]=1;
      nextshape[2][2]=1;
      nextshape[3][1]=1;
      nextc=color(0, 255, 0);
    }
    if (next[i]==7) {//Z赤
      nextshape[1][1]=1;
      nextshape[2][1]=1;
      nextshape[2][2]=1;
      nextshape[3][2]=1;
      nextc=color(255, 0, 0);
    }
    for (int ii=0; ii<4; ii++) {//テトリミノ描画
      for (int jj=0; jj<4; jj++) {
        if (nextshape[ii][jj]==1) {
          strokeWeight(1);
          stroke(0);
          fill(nextc);
          if (i==1) {
            rect(20*ii+665, 20*jj+80*i-45, 20, 20);
          } else {
            rect(20*ii+665, 20*jj+80*i-35, 20, 20);
          }
        }
      }
    }
  }
}


void timeCount() {//フレーム周りの関数
  time++;
  if (obj1.Collide(obj1.shape, obj1.x, obj1.y+1)) {//これ以上落ちれなかったら
    if (stop_time==0) {//遊び時間がない時、テトリミノを固定して新しいのを描画する
      obj1.stopTetris();
      obj1=new Tetrimino();
      stop_time=20;
    } else {//遊び時間
      stop_time--;
    }
  } else {//落下途中
    if (time%speed==0) {//フレームレート（speed）でテトリミノをおとす
      obj1.y++;
      score++;
    }
  }
  //レベルごとの一マス落下にかかるフレーム数
  if (level_count>=30) {
    speed=24;
    level=1;
  } else if (level_count>=40) {
    speed=18;
    level=2;
  } else if (level_count>=60) {
    speed=15;
    level=3;
  } else if (level_count>=80) {
    speed=12;
    level=4;
  } else if (level_count>=100) {
    speed=10;
    level=5;
  } else if (level_count>=120) {
    speed=8;
    level=6;
  }else if (level_count>=140) {
    speed=6;
    level=7;
  }else if (level_count>=160) {
    speed=4;
    level=8;
  }else if (level_count>=180) {
    speed=2;
    level=9;
  }else if (level_count>=200) {
    speed=10;
    level=10;
  }else if (level_count>=210) {
    speed=8;
    level=11;
  }else if (level_count>=220) {
    speed=6;
    level=12;
  }else if (level_count>=230) {
    speed=4;
    level=13;
  }else if (level_count>=240) {
    speed=2;
    level=14;
  }else if (level_count>=250) {
    speed=1;
    if (level_count%10==0) {
      level++;
    }
  }
}



void deleteTetris() {//列が揃った時の処理
  for (int j=0; j<21; j++) {//全ての列を試す
    for (int i=3; i<13; i++) {
      delete_count+=grid[i][j];//横一列のテトリミノの合計
    }
    if (delete_count==10) {//合計が１０（揃って）いたら
      line_count++;//何ライン消去か数える
      level_count++;//消去したラインの合計
      for (int jj=j; jj>1; jj--) {//ライン消す処理
        for (int i=3; i<13; i++) {
          grid[i][jj]=grid[i][jj-1];
          grid_color[i][jj]=grid_color[i][jj-1];
        }
      }
    }
    delete_count=0;
  }
  //スコア
  if (line_count==1) {
    score+=40*(level+1);
    linedelete.rewind();
    linedelete.play();
  } else if (line_count==2) {
    score+=100*(level+1);
    linedelete.rewind();
    linedelete.play();
  } else if (line_count==3) {
    score+=300*(level+1);
    linedelete.rewind();
    linedelete.play();
  } else if (line_count==4) {
    score+=1200*(level+1);
    tetris.rewind();
    tetris.play();
  }
  line_count=0;
}

void shuffleSeven() {//ランダムで1~7を被りなしで決める関数
  for (int i=0; i<7; i++) {
    rand[i]=0;
  }
  for (int i=0; i<7; i++) {
    int randx=(int)random(1, 8);
    for (int j=0; j<7; j++) {
      if (randx!=rand[j]) {
        rand_count++;
      }
    }
    if (rand_count==7) {
      rand[i]=randx;
    } else {
      i--;
    }
    rand_count=0;
  }
}

class Tetrimino {//テトリミノのクラス

  int x=8;
  int y=1;
  int [][] shape= new int [4][4];//形を保存する配列

  Tetrimino() {
    initiate();
  }

  void initiate() {
    for (int i=0; i<4; i++) {
      for (int j=0; j<4; j++) {
        shape[i][j]=0;
      }
    }
    if (next[0]==1) {//I水色
      shape[0][1]=1;
      shape[1][1]=1;
      shape[2][1]=1;
      shape[3][1]=1;
      c=color(0, 255, 255);
    }
    if (next[0]==2) {//O黄色
      shape[1][1]=1;
      shape[1][2]=1;
      shape[2][1]=1;
      shape[2][2]=1;
      c=color(255, 255, 0);
    }
    if (next[0]==3) {//T紫
      shape[1][1]=1;
      shape[2][1]=1;
      shape[3][1]=1;
      shape[2][2]=1;
      c=color(255, 0, 255);
    }
    if (next[0]==4) {//J青
      shape[1][1]=1;
      shape[2][1]=1;
      shape[3][1]=1;
      shape[3][2]=1;
      c=color(0, 0, 255);
    }
    if (next[0]==5) {//Lオレンジ
      shape[1][1]=1;
      shape[2][1]=1;
      shape[3][1]=1;
      shape[1][2]=1;
      c=color(255, 155, 0);
    }
    if (next[0]==6) {//S緑
      shape[1][2]=1;
      shape[2][1]=1;
      shape[2][2]=1;
      shape[3][1]=1;
      c=color(0, 255, 0);
    }
    if (next[0]==7) {//Z赤
      shape[1][1]=1;
      shape[2][1]=1;
      shape[2][2]=1;
      shape[3][2]=1;
      c=color(255, 0, 0);
    }
    //ホールドしてたものが画面外に出ないようにする
    if (Collide(shape, x, y)==true&&hold_change==true) {
      if (Collide(shape, x-1, y)==false) {
        x--;
      } else if (Collide(shape, x+1, y)==false) {
        x++;
      } else if (Collide(shape, x, y-1)==false) {
        y--;
      }
    }
    if (Collide(shape, x, y)==true) {//新しいテトリミノが生み出せない時
      noLoop();
      bgm.close();
      gameover.play();
      textSize(200);
      fill(0, 0, 0, 155);
      rect(0, 0, 960, 640);
      fill(255, 0, 0);
      text("Game Over", 0, 360);
      textSize(50);
      fill(255);
      text("SCORE : "+score, 320, 420);
    }
  }

  void showTetris() {//操作するテトリミノの描画
    for (int i=0; i<4; i++) {
      for (int j=0; j<4; j++) {
        if (shape[i][j]==1) {
          if (Collide(shape, x, y)==false) {
            fill(c);
            rect((x+i-6)*32+320, (y+j-2)*32, 32, 32);
          }
        }
      }
    }
  }

  void stopTetris() {//テトリスが止まった時の関数
    stop.rewind();
    stop.play();
    //フィールドに固定
    for (int i=0; i<4; i++) {
      for (int j=0; j<4; j++) {
        if (shape[i][j]==1) {
          grid[i+x-3][j+y-1]=1;
          grid_color[i+x-3][j+y-1]=c;
        }
      }
    }
    //次のテトリミノを準備する
    for (int i=0; i<6; i++) {
      next[i]=next[i+1];
    }
    next[6]=rand[0];
    for (int i=0; i<6; i++) {
      rand[i]=rand[i+1];
    }
    rand[6]=0;
    if (rand[0]==0) {
      shuffleSeven();
    }
    hold_change=true;//テトリミノが落ち切ったのでホールドできるようになる
  }

  void keyPressed() {
    if (key==CODED) {
      if (keyCode==RIGHT) {//右移動
        if (Collide(shape, x+1, y)==false) {
          move.rewind();
          move.play();
          stop_time=20;
          x++;
        }
      } else if (keyCode==LEFT) {//左移動
        if (Collide(shape, x-1, y)==false) {
          move.rewind();
          move.play();
          stop_time=20;
          x--;
        }
      } else if (keyCode==DOWN) {//高速落下
        if (Collide(shape, x, y+1)==false) {
          y++;
          score++;
        }
      } else if (keyCode==UP) {//ハードドロップ
        for (int i=0; i<22; i++) {
          if (Collide(shape, x, y)==false) {
            obj1.y++;
            score++;
          }
        }
        obj1.y--;
      }
    }
    if (key=='f') {//右回転
      rotate.rewind();
      rotate.play();
      stop_time=20;
      if (Collide(rotateRight(), x, y)==false) {//普通に回転できる時
        rotateOriginRight();
      } else {
        if (Collide(rotateRight(), x-1, y)==false) {//左に移動すれば回転できる時
          shape=rotateRight();
          x--;
        } else if (Collide(rotateRight(), x-1, y)==false) {//右に移動すれば回転できる時
          shape=rotateRight();
          x++;
        } else if (Collide(rotateRight(), x, y--)==false) {//上に移動すれば回転できる時
          y--;
          shape=rotateRight();
        }
      }
    } else if (key=='s') {//左回転
      rotate.rewind();
      rotate.play();
      stop_time=20;
      if (Collide(rotateLeft(), x, y)==false) {//普通に回転できる時
        rotateOriginLeft();
      } else {
        if (Collide(rotateLeft(), x-1, y)==false) {//左に移動すれば回転できる時
          shape=rotateLeft();
          x--;
        } else if (Collide(rotateLeft(), x-1, y)==false) {//右に移動すれば回転できる時
          shape=rotateLeft();
          x++;
        } else if (Collide(rotateLeft(), x, y--)==false) {//上に移動すれば回転できる時
          y--;
          shape=rotateLeft();
        }
      }
    } else if (key==' ') {//ホールド
      if (hold_change) {
        holdm.rewind();
        holdm.play();
        if (hold_first) {//一回目は交換なし
          hold=next[0];
          for (int i=0; i<6; i++) {
            next[i]=next[i+1];
          }
          next[6]=rand[0];
          for (int i=0; i<6; i++) {
            rand[i]=rand[i+1];
          }
          rand[6]=0;
          if (rand[0]==0) {
            shuffleSeven();
          }
          hold_first=false;
        } else {//2回目以降は交換
          int tmp;
          tmp=next[0];
          next[0]=hold;
          hold=tmp;
        }
        initiate();
        hold_change=false;
      }
    }
  }


  int [][] rotateRight() {//右回転
    int [][] tmp1=new int [4][4];
    if (next[0]==1||next[0]==2) {
      for (int i=0; i<4; i++) {
        for (int j=0; j<4; j++) {
          tmp1[j][3-i]=shape[i][j];
        }
      }
    } else {
      for (int i=1; i<4; i++) {
        for (int j=0; j<3; j++) {
          tmp1[j+1][3-i]=shape[i][j] ;
        }
      }
    }
    return tmp1;
  }
  int [][] rotateLeft() {//左回転
    int [][] tmp1=new int [4][4];
    if (next[0]==1||next[0]==2) {
      for (int i=0; i<4; i++) {
        for (int j=0; j<4; j++) {
          tmp1[i][j]=shape[j][3-1];
        }
      }
    } else {
      for (int i=1; i<4; i++) {
        for (int j=0; j<3; j++) {
          tmp1[i][j]=shape[j+1][3-1] ;
        }
      }
    }
    return tmp1;
  }

  void rotateOriginRight() {//右回転
    int [][] tmp1=new int [4][4];
    for (int i=0; i<4; i++) { 
      for (int j=0; j<4; j++) {
        tmp1[i][j] = shape[i][j];
      }
    }
    if (next[0]==1||next[0]==2) {
      for (int i=0; i<4; i++) {
        for (int j=0; j<4; j++) {
          shape[i][j]=tmp1[j][3-i];
        }
      }
    } else {
      for (int i=1; i<4; i++) {
        for (int j=0; j<3; j++) {
          shape[i][j]=tmp1[j+1][3-i] ;
        }
      }
    }
  }
  void rotateOriginLeft() {//左回転
    int [][] tmp1=new int [4][4];
    for (int i=0; i<4; i++) { 
      for (int j=0; j<4; j++) {
        tmp1[i][j] = shape[i][j];
      }
    }
    if (next[0]==1||next[0]==2) {
      for (int i=0; i<4; i++) {
        for (int j=0; j<4; j++) {
          shape[j][3-i]=tmp1[i][j];
        }
      }
    } else {
      for (int i=1; i<4; i++) {
        for (int j=0; j<3; j++) {
          shape[j+1][3-i]=tmp1[i][j] ;
        }
      }
    }
  }

  boolean Collide(int[][] _tmp, int _x, int _y) {//任意の形で移動先が衝突するかどうかの判定
    boolean result = false;
    int[][] tmp= _tmp;
    int xx=_x;
    int yy=_y;
    for (int i=0; i<4; i++) {
      for (int j=0; j<4; j++) {
        if (tmp[i][j]==1&&grid[xx+i-3][yy+j-1]==1) {
          result=true;
        }
      }
    }
    return result;
  }
}
