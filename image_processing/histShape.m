%The function histShape receives 2 greyscale images: srcimg and destimg, and improves the srcimg based on the
%destimg using the Histogram Shape algorithm. That is, it scales the srcimg's histogram's by the destimg histogram
%using a conversion vector, and the result is a new image with more grey
%levels which is clearer. Run using histShape(srcimg, destimg) where the
%arguments are greyscale images after imread.
%Helper methods are:
%getHistogram, getAccHist, getCV
function [newImg] = histShape(srcimg, destimg)
	% Get the sizes of the src and dest images:
	[src_rows , src_cols] = size(srcimg);
	[dest_rows, dest_cols] = size(destimg);
    
	% Get the src and dest images' histogram:
	src_hist = getHistogram(srcimg);
	dest_hist = getHistogram(destimg);
    
	% Get the accumulated histograms for both images, and normalize them:
	src_Ahist = getAccHist(src_hist);
	src_Ahist = src_Ahist./(src_rows*src_cols);
	dest_Ahist = getAccHist(dest_hist);
	dest_Ahist = dest_Ahist./(dest_rows*dest_cols);
    
    % Get the conversion vector using the two acc. histograms:
	cv = getCV(src_Ahist, dest_Ahist);
	
    % Create a new image, then iterate and improve it using the conversion
    % vector (switch it to the matching color found in the CV):
	newImg = srcimg;
    for r=1:src_rows
		for c=1:src_cols
			newImg(r,c) = cv(newImg(r,c)+1);
		end
    end
end

% This method get the source and dest images' normalized accumulated
% histograms and returns a conversion vector. The CV details which color we need to replace the source color to.
function [n_cv] = getCV(source_normal_acc, dest_normal_acc)
    % Initialize s,d counters:
	s=1;
	d=1;
    
    % Calculate the conversion vector, based on the algorithm
    % (compare the accu. histograms to know which
    % value to increase/decrease):
    while s<=256
		if(source_normal_acc(s)>dest_normal_acc(d))
			d=d+1;
		else
			CV(s)=d-1;
			s=s+1;
		end
    end
    
    % Set the return value to the CV:
	n_cv = CV;
end

% This method gets a histogram (origin_hist) and returns an accumulated histogram.
function [accHist] = getAccHist(origin_hist)
	Ahist = origin_hist;
    
    % Calculate the accumulated histogram based on the regular histogram:
    for i=2:256
		Ahist(i) = origin_hist(i) + Ahist(i-1);
    end
    
    % Set the return value:
	accHist = Ahist;
end

% This method gets an image and returns its histogram.
function [new_histogram] = getHistogram(srcimg)
	% Initialize a new histogram, and get the size of the given image:
	my_hist = zeros(1,256);	
	[rows , cols] = size(srcimg);
    
	% Iterate over the image and fill the histogram based on its values,
    % based on the algorithm from the tirgul. For each color we count
    % how many pixels we have of it.
    for r=1:rows
		for c=1:cols
			my_hist(srcimg(r,c)+1) = my_hist(srcimg(r,c)+1)+1;
		end
    end
    
    % Set the return values:
	new_histogram = my_hist;
end
