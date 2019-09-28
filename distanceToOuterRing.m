function [result] = distanceToOuterRing(dieCoordinates,sortedWaferMapEndDieData)
% input:
% 1. dieCoordinates: [1,2]: (x,y) coordinates, [3,4]: theta, rho
% 2. sortedWaferMapEndDieData: end die of a wafer map sorted by its theta value.
%    waferMapEndDieCoordinates = [waferMapEndDieXY,waferMapEndDiePolar];  
%    sortedWaferMapEndDieData = sortrows(waferMapEndDieCoordinates,3);    
% 1,2: x,y coordinates, 3,4: polar: theta, rho

% output:
% result: the vector of distance to outer ring

nDies = size(dieCoordinates,1);
% initialization
result = zeros(nDies,1);

for i = 1:nDies    
    % find the point of two lines intersection given four data points
    % x1: origin, x2: die, x3 and x4: end dies of wafer map    
    % 1: origin
    x1 = 0;
    y1 = 0;
    
    % 2: die information    
    x2 = dieCoordinates(i,1);
    y2 = dieCoordinates(i,2);
    x2Theta = dieCoordinates(i,3);
    x2Rho = dieCoordinates(i,4);
    
    % if the die is the same as origin
    if x2Theta == 0 && x2Rho == 0
        % assign the largest rho value
        result(i) = max(sortedWaferMapEndDieData(:,4));   
        continue;
    end
    
    % check whether the same as one of end die theta value
    idx = ismember(x2Theta,sortedWaferMapEndDieData(:,3));    
    
    if sum(idx) == 1
        result(i) = max(sortedWaferMapEndDieData(idx,4));
    elseif sum(idx) == 0
        % sum(idx) ==0: there are three cases: 
        % two cases are that: x2Theta value is smaller than the first end die theta value or x2Theta value is greater than the last end die theta value
        % the remaining case: die theta value is between two adjacent wafer map end die theta vavlues.
        % x2Theta < sortedWaferMapEndDieData(1,3) || x2Theta > sortedWaferMapEndDieData(end,3): this is specially used for calculated center
        if x2Theta < sortedWaferMapEndDieData(1,3) || x2Theta > sortedWaferMapEndDieData(end,3)
            % 3: choose the first one                   
            x3 = sortedWaferMapEndDieData(1,1);
            y3 = sortedWaferMapEndDieData(1,2);     

            % 4: choose the last one
            x4 = sortedWaferMapEndDieData(end,1);
            y4 = sortedWaferMapEndDieData(end,2);       
        else
            blTheta1 = x2Theta > sortedWaferMapEndDieData(:,3);
            blTheta2 = x2Theta < sortedWaferMapEndDieData(:,3);
            
            % 3: the last true logical data of blTheta1                           
            tempX3 = sortedWaferMapEndDieData(blTheta1,1);
            tempY3 = sortedWaferMapEndDieData(blTheta1,2);     
            x3 = tempX3(end);
            y3 = tempY3(end);

            % 4: the first true logical data of blTheta2
            tempX4 = sortedWaferMapEndDieData(blTheta2,1);
            tempY4 = sortedWaferMapEndDieData(blTheta2,2);            
            x4 = tempX4(1);
            y4 = tempY4(1);
        end
        % find the intersection of two lines
        [px,py] = twoLinesIntersection(x1,y1,x2,y2,x3,y3,x4,y4);

        % distance from origin
        d = sqrt(px*px + py*py);

        result(i) = d;
    end
end
end
