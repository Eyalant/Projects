%This function find circles in the given image using hough transform. It
%first gets the edges from edgeDetect, then iterates over them, finds the
%pixels which could be part of a circle, and eliminates the circles which
%don't fit (using threshold and check for local maximality). It also uses
%tgTeta to determine the direction of an edge pixel to find the center
%paramaters (and radius) accordingly.
function [circles,cImg] = findCircles(img)
  % Perform edge detection using canny (part 1):
  [edges, tgTeta] = edgeDetect(img);
 
  % Initialize the circles matrix and the image w/ the circles on it:
  circles = [];
  cImg = img;
 
  % Initialize the 3D accumulator matrix which will count the pixels:
  count = zeros(size(img, 2), size(img, 1), round(min(size(img,1), size(img,2)) / 2));
 
  % Iterate over the edges, and find all pixels which could
  % be part of a circle (phase 1):
  count = phase1(edges, count, tgTeta, img);
 
  % Define a threshold to be divided by all found radious, then
  % eliminate circles which don't pass the threshold, are not a local
  % maximum or otherwise don't fit (phase 2):
  threshold = 4;
  [circles, cImg] = phase2(count, circles, cImg, img, threshold);
end


% This function iterates over the edges, and finds all pixels which could
% be part of a circle. It then returns the updated 3D accumulator.
function count = phase1(edges, count, tgTeta, img)
    % Iterate over the image:
    for r = 1:size(img, 1)
        for c = 1:size(img, 2)
            % Check if current pixel is an edge:
            if edges(r,c) == 1
                % Get it's gradient from the tgTeta mat.:
                pixel_grad = tgTeta(r, c);
               
                % If the gradient is smaller than -1 or bigger than 1, iterate over the cy's
                % and add the gradient to x:
                if pixel_grad < -1 || pixel_grad > 1
                    count = update_x(r, c, pixel_grad, count, img);
               
                % If the gradient is neither, but in between, iterate over the cx's
                % instead, and add the inverse of the gradient to y:
                elseif pixel_grad > -1 && pixel_grad < 0 || pixel_grad > 0 && pixel_grad < 1
                    count = update_y(r, c, pixel_grad, count, img);
                end
                
                else
                    continue
            end
        end
    end
end

% This function gets the currect r,c, the gradient of the edge
% pixel, the accumulator/count and the original image and
% loops over the cx's to update the y, find a radius and add
% it to the count:
function count = update_y(r, c, pixel_grad, count, img)
% Mark y as the given r index, and start looping over the cx's:
y = r;
for cx = c+1:size(img, 2)
    % Now that the radius parameter is eliminated, find the y that
    % fits the equation b = a*tan(teta) - x*tan(teta) + y (from lecture #7)
    % where currently y is set to r, b as y, a is cx and x is c-1.
    % Then assign it to cy as the y center of the circle.
    y = y + pixel_grad*cx - pixel_grad*(c - 1);
    cy = round(y);
    
    % Reset y for the next iteration, and find the radius that
    % fits the cx and cy we found:
    y = r;
    Radius = round(sqrt((cx-c).^2 + (cy-r).^2));
                       
    % If the radius and the cy are both inside the image (cx
    % is gurranteed to be because we loop over it), increase
    % the count for this radius with those center points:
    if Radius >= 1 && Radius < round(min(size(img,1), size(img,2)) / 2) && cy >= 1 && cy < size(img,1)
        count(cx, cy, Radius) = count(cx, cy, Radius) + 1;
    end
end

end

% This function gets the currect r,c, the gradient of the edge
% pixel, the accumulator/count and the original image and
% loops over the cy's to update the x, find a radius and add
% it to the count:
function count = update_x(r, c, pixel_grad, count, img)
% Mark x as the given c index, and start looping over the cy's:
x = c;

for cy = r+1:size(img, 1)
    % The radius parameter is eliminated, so find the x that
    % fits the same equation as before, only with the inverse of the
    % gradient (to not have 'holes'), and then assign it to cx as the
    % x center of the circle.
    x = x + (1/pixel_grad)*(cy) - (1/pixel_grad)*(r - 1);
    cx = round(x);
    
    % Reset x for the next iteration, and find the radius that
    % fits the cx and cy we found:
    x = c;
    Radius = round(sqrt(abs(cx-c).^2 + abs(cy-r).^2));
    
    % If the radius and the cx are both inside the image (cy
    % is gurranteed to be because we loop over it), increase
    % the count for this radius with those center points:
    if Radius >= 1 && Radius < round(min(size(img,1), size(img,2)) / 2) && cx >= 1 && cx < size(img,2)
        count(cx, cy, Radius) = count(cx, cy, Radius) + 1;
    end
end

end


% This function eliminates circles which don't pass the threshold, are not a local
% maximum or don't fit, and returns the circles matrix and the circled image.
function [circles, cImg] = phase2(count, circles, cImg, img, threshold)
% Init the circle number count:
CircleNumber = 1;

% For each pair of centers and each radius from 5:
for OriginX = 1:size(img, 2)
    for OriginY = 1:size(img, 1)
        for Radius = 5:round(min(size(img,1), size(img,2)) / 2)
            % Make sure that the count of "on" pixels is at least the
            % radius/given threshold, and eliminate radius if it's smaller
            % than size 10 (to avoid small circles which aren't correct):
            if count(OriginX, OriginY, Radius) >= Radius/threshold
              % Also check across all three axes that this circle has the biggest count in the
              % set enviornment (the chosen was 15 neighbours in each
              % axis), and perform some additional checks to make sure that 
              % the circle doesn't strech much beyond the image borders:
              if biggestCount(OriginX, OriginY, Radius, count, 15) && OriginX <= (size(img,1) - Radius/1.5) && OriginY <= (size(img,2) - Radius/1.5) && OriginX - Radius >= 0
                  % A circle was found, so add the circle to the circles matrix,
                  % print it, increase the number of circles and insert it into cImg:
                  circles = [circles; [OriginX, OriginY, Radius]];
                  fprintf('Circle %d: %d, %d, %d\n',[CircleNumber],[OriginX],[OriginY],[Radius]);
                  CircleNumber = CircleNumber + 1;
                  centerX = OriginX;
                  centerY = OriginY;
                  cImg = insertShape(cImg,'circle',[centerX centerY Radius]);
              end
            end
        end
   end
end
end

% This function checks if the given circle (presented by it's center x,
% center y and radius) has the biggest count/accumulation (across all axes) within
% it's given local_size enviornment. It return a boolean which indicates whether
% to keep it or not during phase 2 (= the thresholding).
function bool = biggestCount(OriginX, OriginY, Radius, accu, local_size)
% Get the sizes of the accumulator/count matrix to know the borders:
accu_OriginX_size = size(accu,1);
accu_OriginY_size = size(accu, 2);
accu_Radius_size = size(accu, 3);

% Initialize the ans. to false:
bool = false;

% Create the center x enviornment  (from center_x to the left)
% and make sure it's within the image borders, other return false:
OriginX_start = OriginX - local_size;
if OriginX - local_size <= 0
    OriginX_start = 1;
end

% Create the center y enviornment and make sure it's within
% the image (from center y to the left):
OriginY_start = OriginY - local_size;
if OriginY - local_size <= 0
    return
end

% Create the radius enviornment and make sure it's within
% the image and bigger than 5 (from the radius point to the left):
Radius_start = Radius - local_size;
if Radius_start <= 5
    return
end

% Create the center x enviornment and make sure it's within
% the image (from center x to the right):
OriginX_end = OriginX + local_size;
if OriginX_end > accu_OriginX_size
    return
end

% Create the center y enviornment and make sure it's within
% the image (from center y to the right):
OriginY_end = OriginY + local_size;
if OriginY_end > accu_OriginY_size
    return
end

% Create the radius enviornment and make sure it's within
% the image (from radius to the right):
Radius_end = Radius + local_size;
if Radius_end > accu_Radius_size
    return
end

% Get the enviornment from our accumulator, then reshape it into a single
% vector and check if our circle is indeed locally maximal. Return the boolean accordingly.
local_env = accu(OriginX_start : OriginX_end, OriginY_start : OriginY_end, Radius_start : Radius_end);
if all(accu(OriginX, OriginY, Radius) >= local_env(:))
    bool = true;
else
    bool = false;
end
end