//
//  Evaluator.m
//  ScreenReader
//
//  Created by shine on 7/20/21.
//

#import <Foundation/Foundation.h>
#include "Evaluator.h"
#include <vector>

using namespace std;


struct Weights {
    int height = -10;
    int height_H2 = -100;
    int height_Q4 = -500;
    int holes = -600;
    int hole_depth = -25;
    int hole_depth_sq = 1;
    int clears[4] = {-100, -70, 10, 400};
    int bumpiness = -24;
    int bumpiness_sq = -7;
    int max_well_depth = 50;
    int well_depth = 15;
    int well_placement[10] = {25, -10, 15, 30, 10, 10, 30, 10, -15, 25};
    int tsdCompleteness[3] = {50, 100, 300};
    int tspin_filled_rows = 100;
    int tspin[4] = {-400, 100, 600, 800};
    int wasted_t = -150;
    int b2b_bonus = 150;
    int b2b_break = -150;
};

Weights weights = Weights();

int Evaluate (Future* future) {

    
    vector<vector<int>>& chart = future->chart;
    
    TSpin& tspin = future->tspin;
    int maxHeight = -1;
    int holes = 0;
    int heights[10] = {0,0,0,0,0,0,0,0,0,0}; // first contact with filled
    int values[10]  = {0,0,0,0,0,0,0,0,0,0}; // last contact with empty -1
    int wellValue = 0;
    int wellDepth = 21;
    int wellPos = -1;
    int cellsCoveringHoles = 0;
    int cellsCoveringHoles_sq = 0;
    
    // gets hieght and well pos (if well exists)
    for (int x=0; x<10; x++) {
        for (int y=0; y<20; y++) {
            if (chart[y][x] == 1) {
                maxHeight = max(maxHeight, 20-y);
                heights[x] = max(heights[x], 20-y);
            } else {
                values[x] = min(20-y, values[x]);
            }
        }
    }
    for (int x=0; x<10; x++) {
        if (wellDepth > heights[x]) {
            wellDepth = heights[x];
            wellPos = x;
        }
    }

    // checks for holes and covering cells
    for (int x=0; x<10; x++) {
        bool hole = false;
        for (int y=0; y<20; y++) {
            
            if (g_findTSpins && x >= tspin.pos.x && x < tspin.pos.x +3 && y == tspin.pos.y +1) continue;

            if (y > 0) {
                if (chart[y][x] == 0 && chart[y-1][x] == 1) {
                    if (!hole) {    //if first hole of column, punishes for every filled cell ontop of it
                        hole = true;
                        int cells = min(5, heights[x] - (20-y));
                        cellsCoveringHoles += cells;
                        cellsCoveringHoles_sq = cells * cells;
                    }
                    holes++;
                }
            }
        }
    }
    // gets well value (how many lines it can clear)
    int clearableHeight = 21;
    for (int x=0; x<10; x++)
        if (x != wellPos)
            clearableHeight = min(clearableHeight, values[x]);
    wellValue = clearableHeight - wellDepth;
    
    int totalDifference = 0;
    int totalDifference_sq = 0;
    int prev = 0;
    for (int x=1; x<10; x++) {
        if (x == wellPos) continue;
        
        int diff = abs(heights[x] - heights[prev]);
        totalDifference += diff;
        totalDifference_sq += diff * diff;
        prev = x;
    }

    
    int score = 0;
    score += maxHeight * weights.height;
    if (maxHeight >= 10) score += maxHeight * weights.height_H2;
    if (maxHeight >= 15) score += maxHeight * weights.height_Q4;
    score += holes * weights.holes;
    score += weights.clears[future->clears];
    score += totalDifference * weights.bumpiness;
    score += totalDifference_sq * weights.bumpiness_sq;
    if (wellDepth == 0) score += wellValue * weights.max_well_depth + weights.well_placement[wellPos];
    else  score += wellValue * weights.well_depth + weights.well_placement[wellPos];
    score += cellsCoveringHoles * weights.hole_depth;
    score += cellsCoveringHoles_sq * weights.hole_depth_sq;
    
    // tspins
    
    if (g_findTSpins) {
        score += weights.tsdCompleteness[tspin.completeness -1];
        if (future->executedTSpin != -1) score += weights.tspin[(future->executedTSpin)];
        if (future->piece == 4 && future->executedTSpin == -1) score += weights.wasted_t;
        score += tspin.filledRows * weights.tspin_filled_rows;
    }

    return score;
}


