%This function implements the connected components labeling alg.
%It gets a binary image and returns a mat. with the same size in which each
%connected component is tagged with a different label (sequential).
%First it scans each pixel in the given image, checks if it's an object
%pixel, and determines it's label based on it's 4-connected neighbors
%(if they don't exist, it gets a new one, and if they both exist and have
%different labels, we choose the left one and mark the equivalence).
%After the initial labeling/tagging, we use the equivalence table/matrix
%to create a conversion vector and union the equivalent labels, 
%and finally use the vector on the original image and return the result.
function [newImg] = tagConnectedComponents(img)
    % Pad the image (with background pixels = zeros, to not affect the
    % result) to avoid crashing on the boundaries:
    [rows, cols] = size(img);
	pad_img = zeros(rows+1,cols+1);
	pad_img(2:rows+1, 2:cols+1) = img;
	
	% Perform the first pass (initial labeling) using the padded image and
	% get the matrix as well as the list of equivalencies:
	[res_first_pass, eq_labels_list] = doFirstPass(pad_img);

	% Get the equivalence matrix based on the equivalent labels list we got
	% previously:
	[eq_mat] = getEqMat(eq_labels_list, res_first_pass);
	
	% Calculate the conversion vector based on our matrix:
	cv = getConversionVector(eq_mat);

	% Update the label based on the conversion vector we got (= second
	% pass). For all object pixels we first get the index to search in the
	% conversion vector, then set the value from there to that pixel.
	[rows, cols] = size(res_first_pass);
	for r=1:rows
		for c=1:cols
			if (res_first_pass(r,c) ~= 0)
				cv_label = res_first_pass(r,c);
				res_first_pass(r,c) = cv(cv_label);
			end
		end
	end
	
	% Now that the relevant parts have been updated, trim the pad we added
	% and save the result:
	newImg = res_first_pass(2:rows,2:cols);
end

% This function get a padded image and returns a labeled matrix (which represents components
% in the given image), and a list of equivalent labels:
function [res_first_pass, eq_list] = doFirstPass(paddedImg)
    % Get the size of the padded image, and init. the matrix and the
    % equivalence vector:
	[rows, cols] = size(paddedImg);
	res_first_pass = zeros(rows,cols);
	eq_list = [];
    
    % Initialize the starting label:
	label = 1;
    
    % Start iterating over the image, until we hit an object pixel (=1)
    for r=2:rows
        for c=2:cols
            if paddedImg(r,c) == 1
                % Get the 4-neighbours. It is enough to check the left &
                % above neighbours of the current pixel, as we'll get to
                % all components anyway when we get to the following row.
				above = paddedImg(r-1,c);
				left = paddedImg(r,c-1);
                
				% If both neighbours 'exist', choose the left label for the
				% current pixel:
                if left ==1 && above ==1
					res_first_pass(r,c) = res_first_pass(r,c-1);
					%   If the two neighbours have different labels/tags, we still
					%   choose the left one but also update the adjancey/equivalance matrix:
                    if res_first_pass(r-1,c) ~= res_first_pass(r,c-1)
						eq_list = [eq_list, [res_first_pass(r-1,c); res_first_pass(r,c-1)]];
                    end
                    
				% If only the left pixel is an object pixel, take it's
				% label:
				elseif left == 1 && above == 0
					res_first_pass(r,c) = res_first_pass(r, c-1);
				% If only the above pixel is an object pixel, take it's
				% label:
				elseif left == 0 && above ==1
					res_first_pass(r,c) = res_first_pass(r-1, c);
				% If both neighbours are background pixels (they don't 'exist'), we
				% assign the current label to it and create a new label group:
                else
					res_first_pass(r,c) = label;
                    label = label+1;
                end
            end
        end
    end
    
    % Remove duplicate equivalence labels:
	eq_list = unique(eq_list.','rows').';
end

% This function gets a list of equivalence labels and the initial
% tags/labels matrix, and returns the adjancy/equivalence matrix.
function [eq_mat] = getEqMat(eq_labels_list, res_first_pass)

    % Calc. a vector of all the nonzeros (=labels) in the matrix we got:
	labels_list = nonzeros(res_first_pass);
	labels = unique(labels_list);
    
    % Create the properly sized equivalence matrix. Every label is equivalent to itself,
    % so we can start setting a 1 for each label in it's spot in the matrix:
    eq_mat = zeros(length(labels));
	eq_mat(1:length(labels)+1:end) = 1;
	for i=1:size(eq_labels_list,2)
		% Get the equivalent labels and set them in the matching location
		% in the eq_mat:
		r=eq_labels_list(1,i);
		c=eq_labels_list(2,i);
		eq_mat(r,c)=1;
		eq_mat(c,r)=1;
	end

	% Multiply up to n-1 times to find all path from all labels to others.
	% We stop when there are no changes in the equivalence matrix.
	previous_iteration_mat = eq_mat;
	eq_mat = min(eq_mat^2, 1);
	while ~isequal(eq_mat,previous_iteration_mat)
		previous_iteration_mat = eq_mat;
		eq_mat = eq_mat^2;
		eq_mat = min(eq_mat, 1);
	end
end

% This function gets the equivalence matrix/table, and returns a conversion vector which represents
% for each label the correct connected component.
function cv = getConversionVector(eq_mat)
    % Initialize the conversion vector to the first row of the matrix, and
    % the label to be the next one (for multiplication later):
	cv = eq_mat(1,:);
	label = cv(1)+1;
    
	for i=1:length(cv)
        % Find the column with zero:
		if (cv(i) == 0)
            % Calculate the matching row from the table (to where the column is 0 in the vector)
            % times the next label and add it to the conversion vec.:
            row_times_next_label = eq_mat(i, : )*label;
			cv = row_times_next_label + cv;
			label=label+1;
		end
	end
end