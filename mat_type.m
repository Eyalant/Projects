% Matrix Type Recognision project - MATLAB
%-------------------------------------------------------------------------------------------------%

% This program gets a matrix A, identifies the matrix
% type and returns a list of all types it matches to.
function mat_type = mat_type(A)

% Define a string array of possible matrix types to return and a
% recommended tolerance for comparing floating points
% (to account for possible errors from numeric operations in some cases):
mat_type = repmat({''},16,1);
tol = 1e-14;

% Check if matrix is square by checking if # of rows = # of cols:
if ~diff(size(A))
    mat_type{15} = 'o (square)';
    
    % Check if the mat. is symmetric (A equal to it's transpose). No
    % numeric operations are involved (transpose in MATLAB only
    % replaces indices for each element).
    % (Note: On MATLAB version >2014, we can also use issymmetric(A))
    if isequal(A, A.')
        mat_type{1} = 'a (symmetric)';
    end
    
    % Check if the mat. is anti-symmetric (-A equal to it's transpose).
    % (Note: On MATLAB version >2014, we can also use issymmetric(A, 'skew'))
    if isequal(-A, A.')
        mat_type{2} = 'b (anti-symmetric)';
    end
    
    % Check if the mat. is hermitian (A equal to it's conjugate transpose).
    % No numeric operations are involved (conjugate transpose in MATLAB only
    % replaces indices for each element and signs for complex parts of
    % elements).
    % (Note: On MATLAB version >2014, we can also use ishermitian(A))
    if isequal(A, A')
        mat_type{3} = 'c (hermitian)';
    end
    
    % Check if the mat. is diagnonally dominant, by checking if for all rows, the sum 
    % of the magnitude of diagonal element is equal (weak dominance) or greater than
    % (strict dominance) the sum of magnitudes of all other elements in the
    % row. sum(abs(A), 2) is a column vector containing the sum of the row.
    if all( abs(diag(A)) >= sum(abs(A), 2) - abs(diag(A)) )
        mat_type{7} = 'g (diagonally dominant)';
    end
    
    % Check if the matrix is invertible (nonsingular) by checking if the matrix's reciprocal
    % condition is bigger than a reasonable tolerance. According to MATHWORKS, it's an accurate
    % way to determine singularity (better than checking via the determinant).
    singularity_tol = 1e-12;
    if rcond(full(A)) > singularity_tol
        mat_type{14} = 'n (invertible)';
        
        % Check if the mat. is unitary (The inverse of A is equal to conjugate transpose, up
        % to a reasonable tolerance to account for errors from the inv() command)
        if all(abs(inv(A) - A') < tol)
            mat_type{4} = 'd (unitary)';
        end
    
        % Check if the mat. is orthogonal (The inverse of A is equal to transpose, up
        % to a reasonable tolerance to account for errors from the inv() command)
        if all(abs(inv(A) - A.') < tol)
            mat_type{5} = 'e (orthogonal)';
        end
    end
    
    % Check if A is the identity matrix by comparing them:
    if isequal(A, eye(size(A)))
        mat_type{13} = 'm (identity matrix)';
    end
end

% Check if the matrix is a vandermonde mat. (more detail in the helper function in the bottom):
if check_vandermonde(A,tol)
    mat_type{6} = 'f (vandermonde)';
end

% Check if the matrix is in row-echelon form (more detail in the helper function in the bottom):
if check_row_echelon(A)
    mat_type{8} = 'h (row-echelon form)';
end

% Check if the mat. is upper triangular by checking if all elements below main diagonal are 0s:
% (Note: On MATLAB version >2014, we can also use istriu(A))
if ~any(tril(A,-1))
    mat_type{9} = 'i (upper triangular)';
end

% Check if the mat. is lower triangular by checking all elements above main diagonal are 0s:
% (Note: On MATLAB version >2014, we can also use istril(A))
if ~any(triu(A,1))
    mat_type{10} = 'j (lower triangular)';
end

% Check if the mat. is diagonal by checking if all non-diagonal entries are 0:    
% (Note: On MATLAB version >2014, we can also use isdiag(A) to check)
if ~any(tril(A,-1)) & ~any(triu(A,1))
    mat_type{11} = 'k (diagonal)';
end

% Check if the mat. is tridiagonal by checking if all elements above first superdiagonal
% are 0s and all elements below first subdiagonal are 0s:
% (Note: On MATLAB version >2014, we can also use isbanded(A, 1, 1))
if ~any(tril(A,-2)) & ~any(triu(A,2))
    mat_type{12} = 'l (tridiagonal)';
end

% Check if matrix is sparse by checking if the majority of it's elements
% are 0s, by checking if (all elements - non-zeros)=zeros > non-zeros.
if numel(A) > 2*nnz(A)
    mat_type{16} = 'p (sparse)';
end

% Display results as char array:
mat_type = char(mat_type);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%

% Check if a matrix is a vandermonde matrix:
function bool = check_vandermonde(A, tol)
bool = false;

% Get the # of columns in A:
[~, cols] = size(A);

% If the matrix only has 1 column and it's all ones, it's vandermonde:
if all(A(: , 1) == 1) && cols == 1
    bool = true;
    return
end

% If first column is all ones, take the second column:
if all(A(: , 1) == 1)
    vec = A(: , 2);
% If last column is all ones (alternate form of vander),
% take the second to last column:
elseif all(A(: , end) == 1)
    vec = A(: , end - 1);
% If none of these is true, it's not a vandermonde matrix:
else
    bool = false;
    return
end

% Make B a matrix with size (length(vec), # of columns in A):
B = ones(length(vec) , cols);

% Turn the columns of B (starting from column 2) to a vandermonde matrix,
% based on the column we took (make each row a geometric progression, 
% by multiplying each column with the previous column = less errors than using
% power operation).
for i  = 2 : cols
    B(: ,i) = vec .* B(: , i-1); 
end

% If all elements of A and the newly created B are the same
% up to a tolerance (to take possible errors into account), 
% the matrix is vandermonde:
if all(abs(B - A) < tol) | all(abs(fliplr(B) - A) < tol)
    bool = true;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if the matrix is in row-echelon form:
function bool = check_row_echelon(A)
[rows, ~] = size(A);
for i = 1:rows
    % If this row is a zero row, make sure the following row is also a zero
    % row. If it isn't, return false, and if it is skip to the next row.
    if ~any(A(i, :)) && i < rows
        if any(A(i+1, :))
            bool = false;
            return
        end
        continue
    end
    
    % Find the column index of the leading coefficient in the row (first
    % nonzero element):
    [~, col] = find(A(i,:), 1, 'first');
    
    % Take the column we found, and check if all elements below
    % the leading coefficient in this column are 0s:
    col_vec = A(:,col);
    if any(col_vec(i+1:end))
        bool = false;
        return
    end
end

% If the mat. meets conditions for all rows, it's in row echeleon form:
bool = true;
end