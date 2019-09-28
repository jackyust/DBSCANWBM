clear
datetime('now')
tic;

%% load related data excluding none pattern
load('waferPattern.mat');
% unique({waferPattern.failureType})
%    'Center'    'Donut'    'Edge-Loc'    'Edge-Ring'    'Loc'    'Near-full'    'Random'    'Scratch'

%% parameter setting
% 1: single linkage, 2: dbscan
algorithm = 2; 
% 0: empty dice, 1: good dice, 2: defective dice
emptyDieVal = 0;
goodDieVal = 1;
badDieVal = 2;
nearFullThreshold = 0.70; % 0.7223 (0.7 accurarcy: 1, real: 149, predicted: 175), (0.75 accuracy: 0.9463, predicted: 142)
waferCenter = [0 0];


edgeRingRadiusThreshold = 0.8; % Percentage: 80%


% DBSCAN parameter: (epsilon,minPts): 
% isoloated outlier: [epsilon,minPts] = [1 2];
% isolaoted outlier and twin outlier: [epsilon,minPts] = [sqrt(2) 3];
dbscanEpsilon = sqrt(2); 
dbscanMinPts = 3; 
outlierClusterLabelInDBSCAN = 0;

figurePath = 'D:\MATLAB\';
fileName = 'waferMap';

% imageSize = [256 256]; % [256 256 3]


%%    'Center'    'Donut'    'Edge-Loc'    'Edge-Ring'    'Loc'    'Near-full'    'Random'    'Scratch'
RealCenterIndex = find(strcmp({waferPattern.failureType},'Center')); % 4294
RealDonutIndex = find(strcmp({waferPattern.failureType},'Donut')); % 555
RealEdgeLocIndex = find(strcmp({waferPattern.failureType},'Edge-Loc')); % 5189
RealEdgeRingIndex = find(strcmp({waferPattern.failureType},'Edge-Ring')); % 9680
RealLocIndex = find(strcmp({waferPattern.failureType},'Loc')); % 3593
RealNearFullIndex = find(strcmp({waferPattern.failureType},'Near-full')); % 149, [min,max] = [72.23, 100];
RealRandomIndex = find(strcmp({waferPattern.failureType},'Random')); % 866
RealScratchIndex = find(strcmp({waferPattern.failureType},'Scratch')); % 1193



for waferMapIndex = 1:size(waferPattern,1)
    waferMapIndex  
    waferMap = waferPattern(waferMapIndex).waferMap;    
    mapSize =  size(waferMap);    
    
    % Wafer map information    
    dieSize = waferPattern(waferMapIndex).dieSize;
    failureType = waferPattern(waferMapIndex).failureType;       
     
    %% cartesian and polar coordinates
    % total die x,y coordinates
    [rowIndex,colIndex] = find(waferMap ~= emptyDieVal);
    totalDieXY = XYCoordinatesExtraction(waferMap,rowIndex,colIndex);    
    % polarCoordinates: [theta,rho], theta: value range is in [0,2): means [0, 2*pi)
    totalDiePolar = polarCoordinateExtraction(totalDieXY);
    totalDieCoordinates = [totalDieXY,totalDiePolar];    
    
    % Bad die x,y coordinates
    [rowIndex,colIndex] = find(waferMap == badDieVal);
    nBadDies = numel(rowIndex); % the same as size(badDieXY,1);
    waferPattern(waferMapIndex).nBadDies = nBadDies; 
    
    % if has no any bad die
    if nBadDies  == 0
        waferPattern(waferMapIndex).badDieRatio = 0;
        continue;
    end
    
    % bad die ratio
    badDieRatio = nBadDies / dieSize;  
    waferPattern(waferMapIndex).badDieRatio = badDieRatio;  
    
    badDieXY = XYCoordinatesExtraction(waferMap,rowIndex,colIndex);     
    
    % polarCoordinates: [theta,rho], theta: value range is in [0,2): means [0, 2*pi)
    badDiePolar = polarCoordinateExtraction(badDieXY);
    badDieCoordinates = [badDieXY,badDiePolar];
        
    %% distance at theta of total die, wafer map end die 
    [waferMapEndDieXY,endPositionPercentageOverEndRing,endPositionRatioOverRawXY,endBadDieXY] = endPositionCheck(waferMap,emptyDieVal,badDieXY);
    waferPattern(waferMapIndex).endPositionPercentageOverEndRing = endPositionPercentageOverEndRing;
    waferPattern(waferMapIndex).endPositionRatioOverRawXY = endPositionRatioOverRawXY;       
    
    % wafer map end die polar coordinate extraction
    waferMapEndDiePolar = polarCoordinateExtraction(waferMapEndDieXY);
    waferMapEndDieCoordinates = [waferMapEndDieXY,waferMapEndDiePolar];    
    
    % sort by theta ascending order for line connection 
    % sortedWaferMapEndDieData: [x,y,theta,rho]
    sortedWaferMapEndDieData = sortrows(waferMapEndDieCoordinates,3);    
    disp('sungho');
         
    % totalDieDistanceAtTheta: the distance to origin at the corresponding theta
    totalDieDistanceAtTheta = distanceToOuterRing(totalDieCoordinates,sortedWaferMapEndDieData);
    
    % badDieDistanceAtTheta: the distance to origin at the corresponding theta
    badDieDistanceAtTheta = distanceToOuterRing(badDieCoordinates,sortedWaferMapEndDieData);

    
      
    %% clustering algorithm 
    if algorithm == 1 % single linakge
        Z = linkage(badDieXY,'single','euclidean');
        numCluster = 4;
        % Construct agglomerative clusters from linkages
        clusterLabel = cluster(Z,'maxclust',numCluster);         
    elseif algorithm == 2 % dbscan  
        clusterLabel = DBSCAN(badDieXY,dbscanEpsilon,dbscanMinPts);
    end
    
    %% cluster statistics
    [clusterFrequency, clusterLabelVal] = histcounts(categorical(clusterLabel)); % must use categorical function, it is general for both numeric and categorical cases
    clusterLabelVal = cellfun(@str2double, clusterLabelVal); % convert val from string to numerical
    % clusterCellArray: 1st: cluster label, 2nd: cluster frequency, 3rd:cluster frequency ratio, 4th: regionCenter, 5th: boundary of polygon vertex, 6th: xy coordinates of current cluster
    clusterCellArray = num2cell([clusterLabelVal', clusterFrequency', clusterFrequency' / nBadDies]);
    
    % the number of unique cluster label
    numClusterLabel = numel(clusterLabelVal);
    for iClusterLabel = 1 : numClusterLabel
        currentClusterLabel = clusterLabelVal(iClusterLabel);
        isCurrentCluster = clusterLabel == currentClusterLabel;
        currentClusterXY = badDieXY(isCurrentCluster,:);
        
        regionCenter = [];
        pv = []; % polygon vertex
        % skip outlier
        if currentClusterLabel == outlierClusterLabelInDBSCAN
            regionCenter = [NaN NaN];
            pv = [];
        else
            isColinear = collinear(currentClusterXY,0.001);
            if isColinear
                regionCenter = mean(currentClusterXY);
                pv = [];
            else
                pv = boundary(currentClusterXY(:,1),currentClusterXY(:,2));            
                % assume currentClusterXY(k,:) is polygon vertex
                [regionCenter,~]= polygonCentroid(currentClusterXY(pv,:));                
            end 
        end           
        clusterCellArray{iClusterLabel,4} = [regionCenter(1) regionCenter(2)];
        clusterCellArray{iClusterLabel,5} = pv;
        clusterCellArray{iClusterLabel,6} = currentClusterXY;
    end
    
    %% plot clustering result    
   % since if first gscatter, and then ring radius would result in strange figure, so first plot ring ridus
    % Plot scatter plot and clustering result
    subplot(1,2,1)
    imagesc(waferMap)
    selfColorMap=[ 1 1 1; ... % empty elements use white color
                   0 1 1 ; ... % good dice use cyan color
                   1 0 1 ];    % defective dice use magenta color
    colormap(selfColorMap)
    grid minor;
     % title(['Wafer Map-',int2str(waferMapIndex),',',failureType,':[',int2str(mapSize(1)),',',int2str(mapSize(2)),']']);
    
    subplot(1,2,2)
    % wafer map: outer ring
    x = sortedWaferMapEndDieData(:,1);
    y = sortedWaferMapEndDieData(:,2);    
    plot([x;x(1)],[y;y(1)],'k');
    
    
    % wafer map: edgeRingRadiusThreshold ring (0.8)
    x = edgeRingRadiusThreshold * sortedWaferMapEndDieData(:,1);
    y = edgeRingRadiusThreshold * sortedWaferMapEndDieData(:,2);   
    hold on;
    plot([x;x(1)],[y;y(1)],'k');
    
 
    % wafer map: 0.6 ring
    x = 0.6 * sortedWaferMapEndDieData(:,1);
    y = 0.6 * sortedWaferMapEndDieData(:,2);    
    hold on;
    plot([x;x(1)],[y;y(1)],'k');
    
     
    % wafer map: 0.4 ring
    x = 0.4 * sortedWaferMapEndDieData(:,1);
    y = 0.4 * sortedWaferMapEndDieData(:,2);   
    hold on;
    plot([x;x(1)],[y;y(1)],'k');
    
 
    % wafer map: centerRingRadiusThreshold ring
    x = 0.2 * sortedWaferMapEndDieData(:,1);
    y = 0.2 * sortedWaferMapEndDieData(:,2);    
    hold on;
    plot([x;x(1)],[y;y(1)],'k');    
 
    grid minor;
    hold on;
    gscatter(badDieXY(:,1),badDieXY(:,2),clusterLabel);
    legend('off'); % legend('Location','northeast','Orientation','vertical')
    hold on;
    
    % visulization
    for iClusterLabel = 1 : numClusterLabel
        currentClusterLabel = clusterCellArray{iClusterLabel,1};
        if currentClusterLabel == outlierClusterLabelInDBSCAN
            continue;
        else
            regionCenter = clusterCellArray{iClusterLabel,4};
            plot(regionCenter(1),regionCenter(2),'*');
            
            pv = clusterCellArray{iClusterLabel,5};
            
            if isempty(pv)
                % colinear
                continue;
            else
                currentClusterXY = clusterCellArray{iClusterLabel,6};
                plot(currentClusterXY(pv,1),currentClusterXY(pv,2));                
            end
        end
    end    
    title(['Clustered Wafer Map',int2str(waferMapIndex)]);
    superTitle = [failureType,':[',int2str(mapSize(1)),',',int2str(mapSize(2)),']'];
    suptitle(superTitle);    
    hold off   
    set(gcf,'units','normalized','outerposition',[0 0 1 1]);  % for full, % screen: set(gcf, 'Position', get(0, 'Screensize')); % full screen    
    set(gcf,'Visible','off');
    saveas(gcf,fullfile(figurePath, [fileName,int2str(waferMapIndex),'_',failureType]),'jpg');



end
datetime('now')
toc;
