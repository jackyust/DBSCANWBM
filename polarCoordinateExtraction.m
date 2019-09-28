function [ polarCoordinates ] = polarCoordinateExtraction( badXYDieCoordinates )
% polarCoordinateExtraction: 
% change x, y coordinates to polar coordinates, restrict the output values are in [0,2*pi)

% input:
% 	badXYDieCoordinates: bad die x,y coordinates
% output:
% 	polarCoordinates: the corresponding polar coordinates, value range: [0, 2)

% Due to atan2 in cart2por(), theta values are as follows: ex; [-3.6,-3.1], 
[theta,rho] = cart2pol(badXYDieCoordinates(:,1),badXYDieCoordinates(:,2));  
    
% Remove the period 2*pi from theta, Restrict the theta values are in [0,2*pi)
% find the index of theta value less than 0
minusThetaBoolIndex = theta < 0;
theta(minusThetaBoolIndex) = theta(minusThetaBoolIndex) + 2 * pi;

% represent in pi unit
polarCoordinates = [theta / pi,rho];


