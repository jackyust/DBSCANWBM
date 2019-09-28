function [ badDieCoordinates ] = XYCoordinatesExtraction( waferMap,rowIndex,colIndex )
% wafer map size
[nMapRows,nMapCols] = size(waferMap);

% In all cases, both nMapRows and nMapCols should be + 1. 
% this part is also referenced by ellipseParameterDetection.m
nMapRows = nMapRows + 1;
nMapCols = nMapCols + 1;

% normalization: make center as origin
x = (colIndex - nMapCols/2); 
y = - (rowIndex - nMapRows/2);
% x =  (2*col/nMapCols - 1);
% y = -(2*row/nMapRows - 1);    

badDieCoordinates = [x,y];