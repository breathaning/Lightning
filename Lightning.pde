float GRAVITY = 981;
float GROUND_HEIGHT = 50;
float LIGHTNING_DIG = 20;
float CELESTIAL_REST_ROTATION = -PI * 3 / 4;
float CELESTIAL_TRANSITION_ROTATION = -PI / 2;
float CELESTIAL_TRANSITION_TIME = 1;
float CELESTIAL_DISTANCE;
color SKY_CLEAR_COLOR = color(100, 200, 255);
color SKY_STORM_COLOR = color(30, 0, 80);
color LIGHTNING_COLOR = color(243,170,0);
color SPARK_COLOR = color(255, 230, 0);

float lastClick = -999999;
float lastClickX = 0;

float lastCelestialTransition = -999999;
String celestialObject = "Sun";
String lastCelestialObject = "Moon";

boolean doSummon = false;
float summonX = 0;
float summonY = 0;

int time = millis();

ArrayList<Bolt> boltList = new ArrayList<Bolt>();
ArrayList<Spark> sparkList = new ArrayList<Spark>();

void setup() {
  size(500, 500);
  colorMode(RGB, 255);
  CELESTIAL_DISTANCE = height * 1.2;
}

void draw() {
  time = millis();
  
  if (doSummon) {
    summonLightning(summonX, summonY);
    doSummon = false;
  }
  
  drawBackground();
  drawForeground();
  drawCelestialObject();
  
  int originalBoltListSize = boltList.size();
  for (int i = 0; i < originalBoltListSize; i++) {
    int index = i + boltList.size() - originalBoltListSize;
    Bolt bolt = boltList.get(index);
    bolt.update();
  }
  
  int originalSparkListSize = sparkList.size();
  for (int i = 0; i < originalSparkListSize; i++) {
    int index = i + sparkList.size() - originalSparkListSize;
    Spark spark = sparkList.get(index);
    spark.update();
  }
  
  drawFlash();
}

void mousePressed() {
  doSummon = true;
  summonX = (float)mouseX;
  summonY = (float)mouseY;
}

void summonLightning(float summonX, float summonY) {
  lastClick = time;
  lastClickX = summonX;
  String targetCelestialObject = getTargetCelestialObject();
  if (getCelestialTransitionProgress() % 1 == 0 && celestialObject.equals(targetCelestialObject) == false) {
    lastCelestialObject = celestialObject;
    lastCelestialTransition = time;
  }
  new Bolt(summonX, 0);
  for (int i = 0; i < 16; i++) { 
    new Spark(summonX, (float)(height - GROUND_HEIGHT + LIGHTNING_DIG), (float)(Math.random() * 300 + 400), -PI / 2 + (float)((Math.random() - 0.5) * PI / 4));
  }
}

color randomColor() {
  return color((int)(Math.random() * 256), (int)(Math.random() * 256), (int)(Math.random() * 256));
}

float getCelestialTransitionProgress() {
  float progress = ((time - lastCelestialTransition) / 1000.0) / CELESTIAL_TRANSITION_TIME;
  return Math.max(Math.min(progress, 1), 0);
}

String getNextCelestialObject(String celestialObjectName) {
  if (celestialObjectName.equals("Sun")) {
    return "Moon";
  }
  return "Sun";
}

String getTargetCelestialObject() {
  if (getSkyTransitionProgress() == 1) {
    return "Sun";
  }
  return "Moon";
}

float getSkyTransitionProgress() {
  float progress = (time - lastClick - 1500) / 1000.0;
  return Math.max(Math.min(progress, 1), 0);
}

void drawBackground() {
  float alpha = (time - lastClick - 1500) / 1000.0;
  alpha = Math.max(Math.min(alpha, 1), 0);
  background(lerpColor(SKY_STORM_COLOR, SKY_CLEAR_COLOR, alpha));  
}

void drawForeground() {
  fill(100, 100, 100);
  noStroke();
  rect(0, height - GROUND_HEIGHT, width, GROUND_HEIGHT);
}

void drawFlash() {
  fill(255, 255, 255, 255 * (1 - (time - lastClick) / 1000.0));
  noStroke();
  rect(0, 0, width, height);
}

void drawCelestialObject() {
  pushMatrix();
  translate(0, height);
  rotate(CELESTIAL_REST_ROTATION);
  float transitionProgress = getCelestialTransitionProgress();
  if (transitionProgress > 0.5) {
    celestialObject = getNextCelestialObject(lastCelestialObject);
    rotate((transitionProgress - 1) * CELESTIAL_TRANSITION_ROTATION);
  } else {
    rotate(transitionProgress * CELESTIAL_TRANSITION_ROTATION); 
  }
  if (transitionProgress == 1 && celestialObject != "Sun" && getTargetCelestialObject().equals("Sun")) {
    lastCelestialTransition = time;
    celestialObject = "Moon";
    lastCelestialObject = celestialObject;
  }
  translate(0, CELESTIAL_DISTANCE);
  if (celestialObject.equals("Sun")) {
    drawSun(0, 0, 50);
  } else {
    drawMoon(0, 0, 50);
  }
  popMatrix();
}

void drawSun(float x, float y, float size) {
  fill(255, 255, 0);
  noStroke();
  ellipse(x, y, size, size);
  noFill();
  stroke(255, 255, 0);
  strokeWeight(size / 10);
  pushMatrix();
  float spin = time / 3500.0;
  float rays = 8;
  float rayStart = 0.8;
  rotate(spin);
  for (int i = 0; i < rays; i++) {
    float rayProgress;
    if (i % 2 == 0) {
      rayProgress = (float)Math.sin(time / 1000.0);
    } else {
      rayProgress = (float)Math.sin((time / 1000.0) + PI);
    }
    float rayEnd = rayStart + 0.3 + (0.6 * (rayProgress + 1) / 2);
    line(0, size * rayStart, 0, size * rayEnd);
    rotate(2 * PI / rays);
  }
  popMatrix();
}

void drawMoon(float x, float y, float size) {
  fill(255, 255, 255);
  noStroke();
  ellipse(x, y, size, size);
}

void drawInstantLightning(float beginX, float beginY, float direction, float threshold, float randomX, float randomY, float strokeWeightBase) {
  pushMatrix();
  translate(beginX, beginY);
  rotate(direction);
  float startX = 0;
  float startY = 0;
  float endX = 0;
  float endY = 0;
  while (endX <= threshold) {
    float endMultiplier = 1.01 - (0.5 * (float)Math.pow(endX / threshold, 4));
    if (endMultiplier < 0.01) {
      endMultiplier = 0.01;
    }
    endX = startX + (float)(Math.random() * randomX);
    endY = endMultiplier * startY + (float)((Math.random() - 0.5) * randomY);
    strokeWeight((float)Math.max(0.0, strokeWeightBase * (1.1 - Math.pow(Math.abs(endX - (threshold / 2)) / (threshold / 2), 2))));
    line(startX, startY, endX, endY);
    startX = endX;
    startY = endY;
  }
  popMatrix();
}

class Bolt {
  float startX;
  float startY;
  float creationTime;
  float ageMillis;
  
  Bolt(float startX, float startY) {
    this.startX = startX;
    this.startY = startY;
    this.creationTime = time;
    this.ageMillis = 0;
    boltList.add(this);
  }
  
  void update() {
    ageMillis = time - creationTime;
    if (ageMillis > 1500) {
      destroy();
      return;
    }
    float threshold = height - GROUND_HEIGHT + LIGHTNING_DIG;
    noFill();
    stroke(randomColor(), 800 - (ageMillis / 1.5));
    drawInstantLightning(startX, startY, PI / 2, threshold, 4, 16, 1);
    stroke(color(255, 255, 255), 800 - (ageMillis / 1.5));
    drawInstantLightning(startX, startY, PI / 2, threshold, 6, 8, 2);
    stroke(LIGHTNING_COLOR, 600 - (ageMillis / 1.5));
    drawInstantLightning(startX, startY, PI / 2, threshold, 8, 16, 4);
  }
  
  void destroy() {
    boltList.remove(this); 
  }
}

class Spark {
  float startX;
  float startY;
  float initialVelocityX;
  float initialVelocityY;
  float creationTime;
  float age;
  color strokeColor;
  
  Spark(float startX, float startY, float speed, float direction) {
    this.startX = startX;
    this.startY = startY;
    this.initialVelocityX = speed * (float)Math.cos(direction);
    this.initialVelocityY = speed * (float)Math.sin(direction);
    this.creationTime = time;
    this.age = 0;
    this.strokeColor = randomColor();
    sparkList.add(this);
  }
  
  void update() {
    age = time - creationTime;
    if (age > 1500) {
      destroy();
      return;
    }
    noFill();
    stroke(strokeColor, 750 - (age / 1.5));
    float x = startX + (initialVelocityX * age / 1000) + (float)((Math.random() - 0.5) * 10);
    float y = startY + (initialVelocityY * age / 1000) + (0.5 * GRAVITY * (float)Math.pow(age / 1000, 2)) + (float)((Math.random() - 0.5) * 10);
    drawInstantLightning(x, y, (float)(Math.random() * 2 * PI), 10, 3, 9, 3);
  }
  
  void destroy() {
    sparkList.remove(this);
  }
}

class Patch {
  float x;
  float y;
  Patch(float x, float y) {
    this.x = x;
    this.y = y;
  }
}
