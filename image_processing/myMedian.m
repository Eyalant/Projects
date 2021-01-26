%This function applies a median filter of size [rows cols] on the image,
%and returns the result. Images are assumed to be matrices with values
%in range [0...1].
function [newImg] = myMedian(img,rows,cols)
    % Get the size of img:
    [src_rows, src_cols] = size(img);
    newImg = img;
    
    % Check if the filter rows/cols sizes are even or odd:
    rows_even = (mod(rows, 2) == 0);
    cols_even = (mod(cols, 2) == 0);
    
    % Perform the median filter based on whether the rows/cols sizes are
    % odd/even:
    if (rows_even && ~cols_even)
        % Filter row size is even and the cols size is odd, so the
        % enviornment (window) of a pixel (i,j) is i : i+rows-1 for the rows
        % and normal for the cols (symmetric around j).
        newImg = evenRowsOddCols(src_rows, src_cols, rows, cols, newImg);
        
    elseif (~rows_even && cols_even)
        % Filter row size is odd and the cols size is even, so the
        % enviornment of a pixel (i,j) is normal for the rows (symmetric
        % around i) and j : j+cols-1 for the cols.
        newImg = oddRowsEvenCols(src_rows, src_cols, rows, cols, newImg);
        
    elseif (~rows_even && ~cols_even)
        % Filter size is odd, so the enviornment of a pixel (i,j) is
        % normal (symmetric around i,j).
        newImg = oddRowsOddCols(src_rows, src_cols, rows, cols, newImg);
        
    elseif(rows_even && cols_even)
        % Filter size is even for both rows and cols, so the 
        % enviornment (window) of a pixel (i,j) is i : i+rows-1 for the rows
        % and j : j+cols-1 for the cols.
        newImg = evenRowsEvenCols(src_rows, src_cols, rows, cols, newImg);
    end
end
    
% This helper function returns the median of the enviornment (window) of a
% pixel.
function median = getMedian(window)
    % Make window a vector and sort the values:
    window = window(:); 
    window = sort(window);
    
    % Check the window size to check if it's even or odd:
    window_size = size(window, 1);
    median_index = (window_size + 1) / 2;
    
    if mod(window_size, 2) == 0
        % Even window size. The median will be the average between the
        % two middle values (It is guaranteed to be maximum of 1,
        % because each value is maximum 1).
        median = (window(floor(median_index)) + window(ceil(median_index))) / 2;
    else
        % Odd window size. The median will be middle element. 
        median = window(median_index);
    end
end

% This function applies the median filter where the size of the rows of the
% filter are even while the cols are odd.
function newImg = evenRowsOddCols(src_rows, src_cols, rows, cols, newImg)
    % Iterate over the image:
    for r = 1:src_rows
        for c = 1:src_cols
            % Replace the value of pixel i,j to the median of it's rows x
            % cols enviornment, if the calculation is inside the image boundaries.
            if (r > 0) && (r+rows-1) <= src_rows &&  c-floor(cols/2) > 0 && c+floor(cols/2) <= src_cols
                window = newImg(r:r+rows-1, c-floor(cols/2):c+floor(cols/2));
                newImg(r, c) = getMedian(window);
            end
        end
    end
end

% This function applies the median filter where the size of the rows of the
% filter are odd while the cols are even.
function newImg = oddRowsEvenCols(src_rows, src_cols, rows, cols, newImg)
    % Iterate over the image:
    for r = 1:src_rows
        for c = 1:src_cols
            % Replace the value of pixel i,j to the median of it's rows x
            % cols enviornment, if the calculation is inside the image boundaries.
            if (r-floor(rows/2)) > 0 && (r+floor(rows/2)) <= src_rows &&  (c > 0) && (c+cols-1 <= src_cols)
                window = newImg(r-floor(rows/2):r+floor(rows/2), c:c+cols-1);
                newImg(r, c) = getMedian(window);
            end
        end
    end
end

% This function applies the median filter where the size of the filter is
% odd.
function newImg = oddRowsOddCols(src_rows, src_cols, rows, cols, newImg)
    % Iterate over the image:
    for r = 1:src_rows
        for c = 1:src_cols
            % Replace the value of pixel i,j to the median of it's rows x
            % cols enviornment, if the calculation is inside the image boundaries.
            if (r-floor(rows/2)) > 0 && (r+floor(rows/2)) <= src_rows && (c-floor(cols/2)) > 0 && (c+floor(cols/2)) <= src_cols
                window = newImg(r-floor(rows/2):r+floor(rows/2), c-floor(cols/2):c+floor(cols/2));
                newImg(r, c) = getMedian(window);
            end
        end
    end
end

% This function applies the median filter where the size of the filter is
% even in both rows and cols.
function newImg = evenRowsEvenCols(src_rows, src_cols, rows, cols, newImg)
    % Iterate over the image:
    for r = 1:src_rows
        for c = 1:src_cols
            % Replace the value of pixel i,j to the median of it's rows x
            % cols enviornment, if the calculation is inside the image boundaries.
            if (r > 0) && (r+rows-1) <= src_rows &&  (c > 0) && (c+cols-1 <= src_cols)
                window = newImg(r:r+rows-1, c:c+cols-1);
                newImg(r, c) = getMedian(window);
            end
        end
    end
end