%This function implements the image skeletonization alg.
%It recieves a binary image and returns a new binary image after
%skeletonization. The given binary image is scanned until no changes are made.
%Each pixel with 4-connected neighbors who are all larger than i becomes i+1 (for
%iteration i). This gets us the distance of each pixel from the image's background. 
%Next, the matrix is scanned and every object pixel which is greater than or equal to
%it's 4-connected neighbors is marked.
function [newImg] = skeletonizeImage(img)
	% Padding the given image by background pixels (=0), to avoid crashes on
	% boundaries (boundary pixels shouldn't satisfy the cond.):
	[rows,cols] = size(img);
	pad_img = zeros(rows+2,cols+2);
	pad_img(2:rows+1,2:cols+1) = img;

	% Finding the distance of every pixel from the image's background,
	% stored in a matrix:
	dist_matrix = getEdgeDist(pad_img);
	
	% Set the skeleton pixels based on the matrix:
	newImg = getImgSkeleton(dist_matrix);
end

% This function gets a padded binary image and returns a new matrix which
% represents the distance of every object pixel from the original image background.
function [newImg] = getEdgeDist(img)
    % Get the size of the image and init. the dist (i) to 1:
	[rows,cols] = size(img);
	dist = 1;
	prevImg = zeros(rows,cols);
    
    % Loop as long as the matrix keeps changing:
	while ~isequal(prevImg,img)
		prevImg = img;
		for r=2:rows-1
			for c=2:cols-1
				% Getting the 4's connected neighbors, plus the pixel itself.
				neighbors = [img(r-1,c),img(r,c-1),img(r+1,c),img(r,c+1),img(r,c)];
                
				% Increase the current pixel value if all of it's neighbors
				% are equal or greater than dist (as well as itself).
				if all(neighbors >= dist)
					img(r,c) = dist+1;
				end
			end
        end
        % Increase the distance for the next iteration:
		dist = dist+1;
    end
	newImg = img;
end

% This function gets a matrix which represents the distance of each pixel from its original
% image's background, and returns the skeleton of the original image.
function [skel_img] = getImgSkeleton(dist_matrix)
    % Get the size of the distances mat. and remove the padding as it's no
    % longer needed:
	[rows,cols] = size(dist_matrix);
	skel_img = zeros(rows-2,cols-2);
	for r=2:rows-1
		for c=2:cols-1
			% Get all the neighbors:
			neighbors = [dist_matrix(r-1,c),dist_matrix(r,c-1),dist_matrix(r+1,c),dist_matrix(r,c+1)];
            
			% Set the object pixel to be part of the skeleton if it's value is
			% bigger than/equal to the value of it's neighbors:
			cur_pixel = dist_matrix(r,c);
			if cur_pixel >=1 && all(neighbors <= cur_pixel)
				skel_img(r-1,c-1) = 1;
			end	
		end
	end
end
