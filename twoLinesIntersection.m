function [px,py] = twoLinesIntersection(x1,y1,x2,y2,x3,y3,x4,y4)
% input: given four x,y coordinates of points
% output: intersection of two lines (px,py)

% https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection

item1 = x1 - x2;
item2 = x3 - x4;
item3 = y1 - y2;
item4 = y3 - y4;

item5 = x1*y2 - y1*x2;
item6 = x3*y4 - y3*x4;

denominator = item1*item4 - item3*item2;

px = (item5*item2 - item1*item6) / denominator;
py = (item5*item4 - item3*item6) / denominator;
