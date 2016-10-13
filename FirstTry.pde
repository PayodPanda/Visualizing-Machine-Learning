

import peasy.*;
PeasyCam cam;

Table model;

float[] precip, temperature, prediction;
int[] tillage, actual;
float precipMax, precipMin, temperatureMax, temperatureMin;
int tillageMax, tillageMin;
int count;
float b0, b1, b2, b3, alpha, p;
PFont font;

boolean showDifference, showModel;
IntList order;

void setup() {
    size(displayWidth, displayHeight, P3D);
    cam = new PeasyCam(this, width/2.0, height/2.0, 0, 800);
    ortho();
    smooth(16);
    font = createFont("Consolas", 96);
    textFont(font);

    model = loadTable("Prediction.csv", "header");    
    count = model.getRowCount();

    precip = new float[count];
    temperature = new float[count];
    prediction = new float[count];
    tillage = new int[count];
    actual = new int[count];

    precipMax = 0;
    precipMin = 9999;
    temperatureMax = 0;
    temperatureMin = 9999;
    tillageMax = 0;
    tillageMin = 9999;

    int index = 0;
    order = new IntList();

    for (TableRow row : model.rows()) {

        tillage[index] = row.getInt("Tillage");    // y
        temperature[index] = row.getFloat("AverageT");        //x
        precip[index] = row.getFloat("JulPr");        //z

        actual[index] = row.getInt("tsclero");
        prediction[index] = row.getFloat("dis");

        if (tillage[index] > tillageMax) tillageMax = tillage[index];
        if (precip[index] > precipMax) precipMax = precip[index];
        if (temperature[index] > temperatureMax) temperatureMax = temperature[index];

        if (tillage[index] < tillageMin) tillageMin = tillage[index];
        if (precip[index] < precipMax) precipMin = precip[index];
        if (temperature[index] < temperatureMin) temperatureMin = temperature[index];

        order.append(index);

        index++;
    }

    println(count);

    b0=37;
    b1=-2;
    b2=0;
    b3=0;
    alpha = 0.08;
    p=0;
}


void draw() {
    background(255);
    /*
     PShape predict = createShape();
     predict.beginShape(POINTS);
     predict.fill(0,64);
     predict.stroke(0);
     */
    translate(width/8, height/2, 0);
    scale(0.5);
    float boxSize = 50;
    float probabilitySize = 200;
    strokeWeight(4);
    lights();

    alpha = alpha*0.99999;
    order.shuffle();
    /*
    rotateX(radians(5));
     rotateY(radians(-25));
     */
    for (int j=0; j<model.getRowCount(); j++) {
        int i = order.get(j);
        pushMatrix();
        colorMode(HSB, 1, 100, 100);
        translate(map(temperature[i], temperatureMin, temperatureMax, -width/4, width/4) +  (tillage[i]-1) * width/2, 0, map(precip[i], precipMin, precipMax, -height/2, height/2));    
        //map(tillage[i], tillageMin, tillageMax, (probabilitySize) * (tillageMax-tillageMin), -(probabilitySize) * (tillageMax-tillageMin))
        if(!showModel){
            p = 1/(1+ exp(-(b0 + b1*temperature[i] + /*b2*tillage[i] + */b3*precip[i] )));
            b0 = b0 + alpha * (actual[i] - p) * (1-p) * p * 1;
            b1 = b1 + alpha * (actual[i] - p) * (1-p) * p * temperature[i];
            //b2 = b2 + alpha * (actual[i] - p) * (1-p) * p * tillage[i];
            b3 = b3 + alpha * (actual[i] - p) * (1-p) * p * precip[i];
        } else {
            p = prediction[i];
        }

        if (!showDifference) {
            fill(0.5169 - p, 100, 100);
            noStroke();
            translate(0, -(p*probabilitySize)/2, 0);
            box(boxSize, -(p*probabilitySize), boxSize);

            if (actual[i] == 1) {
                noFill();
                stroke(0);
                translate(0, -((actual[i] - p)*probabilitySize)/2, 0);        
                box(boxSize, -(actual[i]*probabilitySize), boxSize);
            }
        } else {
            fill(0.5169 - p, 100, 100);
            noStroke();
            if (abs(actual[i]-p) > 0.5) {
                stroke(0, 100, 100);
            }
            translate(0, -((actual[i]-p)*probabilitySize)/2, 0);
            box(boxSize, -((actual[i]-p)*probabilitySize), boxSize);
        }

        /*
        if(!showDifference){
         fill(0.5169 - prediction[i], 100, 100);
         noStroke();
         translate(0, -(prediction[i]*probabilitySize)/2, 0);
         box(boxSize, -(prediction[i]*probabilitySize), boxSize);
         
         if(actual[i] == 1){
         noFill();
         stroke(0);
         translate(0, -((actual[i] - prediction[i])*probabilitySize)/2, 0);        
         box(boxSize, -(actual[i]*probabilitySize), boxSize);
         }
         } else {
         fill(0.5169 - prediction[i], 100, 100);
         noStroke();
         if(abs(actual[i]-prediction[i]) > 0.99) {
         stroke(0, 100, 100);
         }
         translate(0, -((actual[i]-prediction[i])*probabilitySize)/2, 0);
         box(boxSize, -((actual[i]-prediction[i])*probabilitySize), boxSize);        
         }*/
        colorMode(RGB, 255, 255, 255);
        popMatrix();
    }
    //predict.endShape();

    /*
    PShape data = createShape();
     data.beginShape(POINTS);
     data.fill(0,64);
     data.stroke(255,0,0);
     for(int i=0; i<model.getRowCount(); i++){
     data.translate(map(temperature[i], 0, temperatureMax, 0, width), map(tillage[i], 0, 3, 0, height) + (actual[i]*20), precip[i]);
     }
     data.endShape();
     
     shape(predict);
     shape(data);
     */

    cam.beginHUD();
    {
        textSize(16);
        fill(0);
        text("   b0: " + nfs(b0, 2, 6) + "\n   b1: " + nfs(b1, 2, 6) + "\n   b2: " + nfs(b2, 2, 6) + "\n   b3: " + nfs(b3, 2, 6) + "\n\nalpha: " + nfs(alpha, 2, 6) + "\nepoch:  " + frameCount, 20, 100);
    }
    cam.endHUD();
}

void keyPressed() {
    if (key == ' ') {
        showDifference = !showDifference;
    }
    if(key== 'p'){
        showModel = !showModel;
    }
    if (key == CODED) {
        if (keyCode == UP) {
            alpha += 0.01;
        } else {
            if (keyCode == DOWN) {
                alpha -= 0.01;
            }
        }
    }
}