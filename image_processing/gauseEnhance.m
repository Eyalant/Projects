%This function adds gaussian noise to the given image, then tries to
%enhance it using directional smoothing with five 7x7 filters and
%returns both the enhanced image and the noisy image. 
%The filters used in the directional smoothing are:
%(1) 7x7 filter with a vertical line of 1s in the middle.
%(2) 7x7 filter with a horizontal line of 1s in the middle.
%(3) 7x7 filter with a upper-left to bottom-right diagonal of 1s.
%(4) 7x7 filter with a upper-right to bottom-left diagonal of 1s.
%(5) 7x7 filter filled with 1s.
%(All filters are divided so that the sum of weights are 1 to maintain
%the brightness).
function [eImg,nImg] = gauseEnhance(img)
    % Add gaussian noise to the image:
    nImg = imnoise(img, 'gaussian', 0, 0.004);
    
    % Create an array of filters with five 7x7 filters:
    num_of_filters = 5;
    filters = createFilters(num_of_filters);
    conv_results = performConv(filters, nImg);
    
    % Store the convolution results in variables (needed because cascaded indexing
    % (=indexing in temp arrays) is not possible without using subsref):
    conv_result1 = conv_results(:, :, 1);
    conv_result2 = conv_results(:, :, 2);
    conv_result3 = conv_results(:, :, 3);
    conv_result4 = conv_results(:, :, 4);
    conv_result5 = conv_results(:, :, 5);
    
    % For each pixel in the new image, select the one which is the closest
    % to the original (=noisy) (from the 5 convolution results):
    eImg = nImg;
    for i=1:size(eImg, 1)
        for j=1:size(eImg, 2)
            % Create a vector with each of the filters in the pixel i,j:
            filters_in_pixel_vector = [conv_result1(i,j), conv_result2(i,j), conv_result3(i,j), conv_result4(i,j), conv_result5(i,j)];
            
            % Find the differences between the noisy image and the
            % filtered ones, then choose the filter with the smallest
            % difference and place it into this pixel in eImg:
            array_of_differences = abs(nImg(i,j) - filters_in_pixel_vector);
            [~, minIndex] = min(array_of_differences);
            eImg(i, j) = filters_in_pixel_vector(minIndex);
        end
    end
end


% This function creates several 7x7 filters, adds them to an array and
% returns it.
function [filters] = createFilters(num_of_filters)
    % Create several 7x7 filters and add them to the filter array:
    filters = zeros(7, 7, num_of_filters);
    
    % A filter with a vertical line in the middle:
    filter1_vertical = zeros(7,7);
    filter1_vertical(:, 4) = 1/7;
    
    % A filter with a horizontal line in the middle:
    filter2_horizontal = zeros(7,7);
    filter2_horizontal(4, :) = 1/7;
    
    % A filter with a diagonal from left to right:
    filter3_diag_left = diag([1/7, 1/7, 1/7, 1/7, 1/7, 1/7, 1/7]);
    
    % A filter with a diagonal from right to left:
    filter4_diag_right = fliplr(filter3_diag_left);
    
    % A filter filled with values:
    filter5_full_matrix = repmat(1/49, 7, 7);
    
    % Add all of those to the array:
    filters(:, :, 1) = filter1_vertical;
    filters(:, :, 2) = filter2_horizontal;
    filters(:, :, 3) = filter3_diag_left;
    filters(:, :, 4) = filter4_diag_right;
    filters(:, :, 5) = filter5_full_matrix;
end


% This function iterates over the filters and perform a convolution with
% the noisy image, then adds the result to the convolution results array and returns
% it.
function conv_results = performConv(filters, nImg) 

    % Create an array of convolution results:
    conv_results = zeros(size(nImg, 1), size(nImg, 2), size(filters, 3));
    
    % Perform a convolution with each filter in the filter array. Make sure
    % the max value of the result pixels is 1.
    for i=1:size(filters, 3)
        mask = filters(:, :, i);
        result = min(conv2(nImg, mask, 'same'), 1);
        conv_results(:, :, i) = result;
    end
end