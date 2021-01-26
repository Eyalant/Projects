%This function uses the canny edge detector to find edges in the given
%image. It then returns both the image with the edges and the tgTeta matrix
%which consists of the gradients. It first smooths the image using a
%gaussian filter, then calculates the gradients and tgTeta, performs
%non-maximum supression using the directions and magnitudes matrices and
%then uses hi/lo thresholds to find the edges.
function [newImg, tgTeta] = edgeDetect(img)
% First, smooth the image using a 5x5 gaussian filter:
img = applyFilter(img);

% Calculate gradients of gaussian derivative and accordingly, get tgTeta:
[dx, dy] = calcGrads(img);
tgTeta = (dy ./ dx);

% Init. directions and magnitudes (abs(S(x) in the slides) matrices:
[tg_rows, tg_cols] = size(tgTeta);
directions = zeros(tg_rows,tg_cols);

% Fill the magnitudes matrix using dx, dy:
magnitudes = sqrt((dx).^2 + (dy).^2);

% Fill the directions matrix. For each pixel, mark which of it's neighbours to check
% based on it's tgTeta value:
for r = 1 : tg_rows
    for c = 1 : tg_cols
        current_pixel = tgTeta(r, c);
        directions(r, c) = pixelDirection(current_pixel);
    end
end

% Perform Non-Maximum Supression using our two matrices:
nms = NMS(directions, magnitudes);

% Use the hysteresis threshold (double threshold). The chosen hi/lo
% thresholds are based on the gray-levels threshold offered in graythresh
% with the parameters (multipliers) which provided the best output.
newImg = doubleThreshold(nms, 0.7*graythresh(nms), 0.1*graythresh(nms));

end

% This function marks the actual edges based on the hi/low threshold
% it recieves and the magnitude matrix (after NMS). It marks pixels who
% surpass the threshold as edge pixels, and pixels in between low & high
% as edges if some pixel from their 8-connected neighbours is.
function newImg = doubleThreshold(nms, high_thresh, low_thresh)
% Perform a first pass (downwards):
[rows, cols] = size(nms);
newImg = zeros(rows, cols);
for r = 2:rows - 1
    for c = 2:cols - 1
        % If the pixel's magnitude is higher than high threshold, mark this
        % pixel as an edge pixel:
        if nms(r, c) > high_thresh
            newImg(r,c) = 1;
            
        elseif nms(r, c) > low_thresh
            % If the pixel is bigger than the low threshold and one of it's 8-connected neighbours is
            % an edge, it's also an edge (thus chaining the edges):
            eight_neighbours = [nms(r, c-1), nms(r,c+1), nms(r+1, c), nms(r-1, c), nms(r+1,c+1), nms(r+1, c-1), nms(r-1, c-1), nms(r-1, c+1)];
            if any(eight_neighbours == 1)
                newImg(r, c) = 1;
            end
        end
    end
end

% Second pass (similar, but upwards, to propagate and make sure we
% end up marking all edge pixels):
for i = rows-1 : -1 : 2
    for j = cols-1 : -1 : 2
        if nms(i, j) > high_thresh
            newImg(i,j) = 1;
            
        elseif nms(i, j) > low_thresh
            eight_neighbours = [nms(i, j-1), nms(i, j+1), nms(i+1, j), nms(i-1, j), nms(i+1, j+1), nms(i+1, j-1), nms(i-1, j-1), nms(i-1, j+1)];
            if any(eight_neighbours == 1)
                newImg(i,j) = 1;
            end
        end
    end
end
end

% This function performs non-maximum supressing based on the two
% given matrices. It fetches the neighbours of each pixel based on the
% marked direction and checks if the pixel is bigger than them. If so,
% it's marked as an edge.
function nms = NMS(directions, magnitudes)
[rows, cols] = size(magnitudes);
e = zeros(rows, cols);
for i = 2:rows-1
    for j = 2:cols-1
        % Get the direction of the current pixel:
        current = directions(i, j);
        
        % Based on the direction, fetch the matching neighbours to check
        % with:
        if current == 0
            % Horizontal Line:
            neighbours = [magnitudes(i, j-1), magnitudes(i, j+1)];
        elseif current == 1
            % Right Diag:
            neighbours = [magnitudes(i-1, j+1), magnitudes(i+1, j-1)];
        elseif current == 2
            % Vertical Line:
            neighbours = [magnitudes(i-1, j), magnitudes(i+1, j)];
        elseif current == 3
            % Left Diag:
            neighbours = [magnitudes(i-1, j-1), magnitudes(i+1, j+1)];
        end
        
        % Mark this pixel as an edge only if it's magnitude is bigger than 
        % the two neighbours in it's direction:
       if all(magnitudes(i,j) > neighbours)
           e(i,j) = magnitudes(i,j);
       end
     end
end

nms = e;
end

% This function performs smoothing/blurring of the image
% to reduce noise before starting the process (using a gaussian
% filter).
function filtered = applyFilter(img)
% Make a 5x5 gaussian filter (with sig=2) and apply it to the image:
gaus_kernel = fspecial('gaussian', 5, 2);
filtered = conv2(img, gaus_kernel, 'same');
end


% This function returns the dx,dy after conv. with an approx.
% of the derivative of gaussian:
function [dx, dy] = calcGrads(img)
% Perform a convolution with derivative of gaussian (approx.):
dx = conv2(img, [1 -1], 'same');
dy = conv2(img, [1 -1]', 'same');
end

% This function recieves the tangent value of a pixel and
% based on it decides which case is relevant for it - i.e. which
% neighbours to check with later in the NMS stage. Cases
% are from the slides:
function direction = pixelDirection(tangent)
% Set a default value:
direction = 0;

if tangent > -0.4142 && tangent <= 0.4142
    % An horizontal Line:
    direction = 0;
elseif tangent > 0.4142 && tangent < 2.4142
    % The right diag:
    direction = 1;
elseif abs(tangent) >= 2.4142
    % A vertical line:
    direction = 2;
elseif tangent > -2.4142 && tangent <= -0.4142
    % The left diag:
    direction = 3;
end

end

% This function performs initial thresholding of the magnitudes matrix
% (could be needed only based on the slides in the canny presentation,
% but unused).
function newImg = firstThreshold(magnitudes, threshold)
[r,c] = size(magnitudes);
newImg = zeros(r,c);
for i = 1:r
    for j = 1:c
        if magnitudes(i,j) > threshold
            newImg(i,j) = magnitudes(i,j);
        end
    end
end
end