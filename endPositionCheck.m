function [waferMapEndDieXY,endPositionPercentageOverEndRing,endPositionRatioOverRawXY,endBadDieXY] = endPositionCheck(waferMap,emptyDieVal,badDieXY)
% this function is used to extract the end position of a given wafer
% input: 
% 1. waferMap: wafer map
% 2. emptyDieVal: empty die value(need to find non empty value die)
% 3. badDieXY: bad die (x,y) coordinates

% output:
% 1. endPositionArray: % 1st col: row index, 2nd: left side first non zero position, 3rd: right side the last non zero position
% 2. endPositionRatio: the end die percentage over the end ring

% initialization
waferMapEndDieXY = []; 

endPositionRatioOverRawXY = 0;

% All die coordinates except empty dies
[rowIndex,colIndex] = find(waferMap ~= emptyDieVal);

% check each die in horizonal line and vertial line 
endDieRowColIndex = [];
for i = 1:numel(rowIndex)
    a1 = false;
    a2 = false;
    a3 = false;
    a4 = false;
    
    % column of the first non empty die
    col1 = find(waferMap(rowIndex(i),:) ~= emptyDieVal,1,'first');
    if colIndex(i) == col1 
        a1 = true;
    end
    
    % column of the last non empty die
    col2 = find(waferMap(rowIndex(i),:) ~= emptyDieVal,1,'last');
    if colIndex(i) == col2
        a2 = true;
    end
    
    % row of the first non empty die
    row1 = find(waferMap(:,colIndex(i)) ~= emptyDieVal,1,'first');
    if rowIndex(i) == row1
        a3 = true;
    end
    
    % row of the last non empty die
    row2 = find(waferMap(:,colIndex(i)) ~= emptyDieVal,1,'last');
    if rowIndex(i) == row2
        a4 = true;
    end
    
    if any([a1 a2 a3 a4])
        endDieRowColIndex(end + 1,:) = [rowIndex(i),colIndex(i)];
    end
end

% extract x,y coordinates with row and column index
waferMapEndDieXY = XYCoordinatesExtraction( waferMap,endDieRowColIndex(:,1),endDieRowColIndex(:,2) );

% the number of bad dies
nBadDies = size(badDieXY,1);

% check how many dies are at end dies
isEndBadDie = ismember(badDieXY,waferMapEndDieXY,'rows');
nEndBadDieCount = sum(isEndBadDie);
endBadDieXY = badDieXY(isEndBadDie,:);


% the percentage
endPositionPercentageOverEndRing = nEndBadDieCount / size(waferMapEndDieXY,1);
endPositionRatioOverRawXY = nEndBadDieCount / nBadDies;







