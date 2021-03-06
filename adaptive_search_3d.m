% Usage:
% adaptive_search(target_fun, xmin, xmax, ymax, zmin, zmax, mesh_size, max_recursion)
% returns: keys (nx2), vals(nx1)

% Define a wrapper function which Matlab requires
function [ret_keys, ret_vals] = adaptive_search_3d(f, xmin, xmax, ymin, ymax, zmin, zmax, mesh_size, max_recursion)

% Cached version of target function (a variation from adaptive V0.1 script)
function ret = f_cached(x, y, z, val, MODE)
    % Specify cache look up precision
    PRECISION = 6;
	
    persistent cache;
    
    if isempty(cache)
        cache = containers.Map;
    end
	
	% Generate lookup key in cache
	% Automatic rounding is built-in with num2str function
	cache_key = num2str([x y z], PRECISION);
	
	% Mode: 0 -> CALCULATE MODE
	% Used when first calculating all points
	if MODE == 0
		% Check if key exists in cache
        if cache.isKey(cache_key) == 0
			% Calculate and store if key doesn't exist
			fval = f(x, y, z);
			cache(cache_key) = fval;
			% fprintf('->Cache not used\n'); % DEBUG
        else
            fval = cache(cache_key);
			%fprintf('Something is wrong');
        end
        
	ret = fval;
        
	% Mode: 1 -> RETRIEVE MODE
	% Used within checker function
	elseif MODE == 1	
		% Check if key exists in cache
        if cache.isKey(cache_key) == 0
			% Variation in V0.2 to return NaN if the value is not stored
			% This is to ensure we don't do extra calculation unless instructed
			fval = NaN;
		else 
			% Retrieve if key exists
			fval = cache(cache_key);
        end
        ret = fval;
    
    % Mode: 2 -> DUMP MODE
    % Use to retrieve the cache in which all points and data are stored
    elseif MODE == 2
        ret = cache;
	
	% MODE: 3 -> SET MODE
	elseif MODE == 3
		fval = val;
		cache(cache_key) = fval;
        ret = 0;
	end
end

% Cached and periodic version of target function
% Included Mode to be consistent with f_cached
function ret = f_cached_periodic(x, y, z, val, MODE)
	% Constants
	XPERIOD = 1; % Periodity in x 
	YPERIOD = 1; % Periodity in y
	ZPERIOD = 1; % Periodity in z
	
    % Periodic condition
	if x > XPERIOD
		x = x - XPERIOD;
	elseif x < 0
		x = x + XPERIOD;
	end
	
	if y > YPERIOD
		y = y - YPERIOD;
	elseif y < 0
		y = y + YPERIOD;
    end
	
    if z > ZPERIOD
		z = z - YPERIOD;
	elseif z < 0
		z = z + YPERIOD;
	end
	
	ret = f_cached(x, y, z, val, MODE);
end

% Function to generate meshgrid of coordinates 
function [X, Y] = coord_meshgrid(xmin, xmax, ymin, ymax, mesh_size)

    % Update in V0.4: Matlab doesn't support underscore _, it is replaced
    % by t to denote temporary
	tx = linspace(xmin, xmax, mesh_size(1));
	ty = linspace(ymin, ymax, mesh_size(2));
	[X, Y] = meshgrid(tx, ty);
end

% Function to convert meshgrid of coordinates to cellgrid of coordinates
function coord_cellgrid = mesh2cell(X, Y)
	mapper = @(x, y) [x y]; % Mapper function to convert coords to vector 
	coord_cellgrid = arrayfun(mapper, X, Y, 'un', 0); % Tested on GNU Octave
end

% Function to convert cellgrid of coordinates to meshgrid of coordinates
function [X, Y] = cell2mesh(coord_cellgrid)
	mesh_size = size(coord_cellgrid); % Get the size of mesh
	
	% Generate index mesh to retrieve data from cellgrid
    % Update in V0.4: Matlab doesn't support underscore _, it is replaced
    % by t to denote temporary    
	ta = 1 : mesh_size(1); 
	tb = 1 : mesh_size(2); 
	[tA, tB] = meshgrid(ta, tb);
	
	% Mapper function to retrieve x and y respectively
	inverse_mapper_x = @(a, b) coord_cellgrid{a, b}(1); % Inverse map for X
	inverse_mapper_y = @(a, b) coord_cellgrid{a, b}(2); % Inverse map for Y
	
	% Apply mapper function to collectively retrieve X and Y from cellgrid
	X = arrayfun(inverse_mapper_x, tB, tA); % _B and _A has to be in this order
	Y = arrayfun(inverse_mapper_y, tB, tA); % to correctly retrieve X and Y	
end

% Function to generate meshgrid based on mesh_size and starting values
function [X, Y, Z] = coord_meshgrid3D(xmin, xmax, ymin, ymax, zmin, zmax, mesh_size)

    % Update in V0.1: Matlab doesn't support underscore _, it is replaced
    % by t to denote temporary
	tx = linspace(xmin, xmax, mesh_size(1));
	ty = linspace(ymin, ymax, mesh_size(2));
    tz = linspace(zmin, zmax, mesh_size(3));
    
	[X, Y, Z] = meshgrid(tx, ty, tz);
end % coord_meshgrid

% Function to convert meshgrid of coordinates to cellgrid of coordinates
function coord_cellgrid = mesh2cell3D(X, Y, Z)
	mapper = @(x, y, z) [x y z]; % Mapper function to convert coords to vector 
	coord_cellgrid = arrayfun(mapper, X, Y, Z, 'un', 0); 
end

% Function to convert cellgrid of coordinates to meshgrid of coordinates
function [X, Y, Z] = cell2mesh3D(coord_cellgrid)
	t_mesh_size = size(coord_cellgrid); % Get the size of mesh
	
	% Generate index mesh to retrieve data from cellgrid
    % Update in V0.4: Matlab doesn't support underscore _, it is replaced
    % by t to denote temporary    
	ta = 1 : t_mesh_size(1); 
	tb = 1 : t_mesh_size(2); 
    tc = 1 : t_mesh_size(3);
	[tA, tB, tC] = meshgrid(ta, tb, tc);
	
	% Mapper function to retrieve x and y respectively
	inverse_mapper_x = @(a, b, c) coord_cellgrid{a, b, c}(1); % Inverse map for X
	inverse_mapper_y = @(a, b, c) coord_cellgrid{a, b, c}(2); % Inverse map for Y
	inverse_mapper_z = @(a, b, c) coord_cellgrid{a, b, c}(3); % inverse map for Z
	
    % Apply mapper function to collectively retrieve X and Y from cellgrid
	X = permute(arrayfun(inverse_mapper_x, tA, tB, tC),[2,1,3]); 
	Y = permute(arrayfun(inverse_mapper_y, tA, tB, tC),[2,1,3]); 	
    Z = permute(arrayfun(inverse_mapper_z, tA, tB, tC),[2,1,3]); 
end % cell2mesh

% Function subcell returns a cell array of subcells (2D) which are obtained
% from a cell array (3D)
function ret = subcell(cell_3d, mode)
    cell_size = size(cell_3d);
    lx = cell_size(1);
    ly = cell_size(2);
    lz = cell_size(3);
    if mode == 1 % first index fixed 
        
        % It's important to note the ordering
        subcells = cell(ly, 1);
        for i = 1 : ly
            % generate a new cell array
            new_cell = cell(lz, lx);
            
            for j = 1 : lz
                for k = 1 : lx
                    % copy elements to the new cell array
                    new_cell{j, k} = cell_3d{k, i, j};
                end
            end
            
            % append the new cell array to the list of cell arrays
            subcells{i} = new_cell;
        end
        
        ret = subcells;        

    elseif mode == 2 % second index fixed
        
        subcells = cell(lx, 1);
        for i = 1 : lx
            % generate a new cell array
            new_cell = cell(ly, lz);
            
            for j = 1 : ly
                for k = 1 : lz
                    % copy elements to the new cell array
                    new_cell{j, k} = cell_3d{i, j, k};
                end
            end
            
            % append the new cell array to the list of cell arrays
            subcells{i} = new_cell;
        end
        ret = subcells;      
        
    elseif mode == 3 % third index fixed
        subcells = cell(lz, 1);
        for i = 1 : lz
            % generate a new cell array
            new_cell = cell(lx, ly);
            
            for j = 1 : lx
                for k = 1 : ly
                    % copy elements to the new cell array
                    new_cell{j, k} = cell_3d{j, k, i};
                end
            end
            
            % append the new cell array to the list of cell arrays
            subcells{i} = new_cell;
        end
        
        ret = subcells;
    
    else
        fprintf('Invalid Mode');
        ret = 0;
    end
end % subcell


% Checker function, implement four points checking algorithm here
% return true if finds a special region of interest and false otherwise
function ret = checker(x1, x2, x3, x4)
	% Define threshold of checker function
	THRESHOLD = 0.3;
	
	% Condition checks
	if abs(x1 - x2) > THRESHOLD || abs(x1 - x3) > THRESHOLD || abs(x1 - x4) > THRESHOLD
		ret = true; 
	elseif abs(x2 - x3) > THRESHOLD || abs(x2 - x4) > THRESHOLD
		ret = true;
	elseif abs(x3 - x4) > THRESHOLD
		ret = true;
	else
		ret = false;
	end
end

function ret = get_all_points()
    % The first two parameters are placeholders
    ret = f_cached(0, 0, 0, 0, 2);
end

% Function used to do the adaptive search with important update for V0.2
% It incorporates the use of NaN to save the amount of calculation
% Checker function remains the same
% init_weight is used for weight calculation
function ret = t_adaptive_search_2D(fun, coord_cellgrid, MAX_RECURSION)

	% flag:	false if checker has found a special region
	%		true if all points pass the checker function
	
	% Initialize empty array for future return
	ret = []; % TODO: initialize for speed
	
	% Get the mesh_size
	t_mesh_size = size(coord_cellgrid);

    % Calculate each point and store them in cache
    fvals = zeros(t_mesh_size(1), t_mesh_size(2));
    for i = 1 : t_mesh_size(1)
        for j = 1 : t_mesh_size(2)
            params = coord_cellgrid{i, j};
            % The point could have been calculated before, hence we use mode 0
            fval = fun(params(1), params(2), params(3), 0, 0);
            fvals(i, j) = fval;
        end
    end
    
	% A counter used to keep track of the index of the box of interests
	counter = 1;
	
	% Scan fvals with checker function to find points of interests
	for i = 1 : t_mesh_size(1) - 1
		for j = 1 : t_mesh_size(2) - 1
			% fprintf('-> now calculating %d, %d \n', i, j); # DEBUG
			% Four values to send to checker function (clockwise)
			f1 = fvals(i, j);
			f2 = fvals(i, j+1);
			f3 = fvals(i+1, j+1);
			f4 = fvals(i+1, j);
			
			% Get the coordinates of the 2x2 mesh (clockwise)
			x1 = coord_cellgrid{i, j};
			x2 = coord_cellgrid{i, j+1};
			x3 = coord_cellgrid{i+1, j+1};
			x4 = coord_cellgrid{i+1, j};
				
			% Get the coordinates of new points based on the center point
            x0 = (x1 + x2 + x3 + x4) / 4; % Equivalent to x1 + x3 / 2
            
			% When a special region is identified
			% Important: the parameters contain NaN sometimes	
			if checker(f1, f2, f3, f4) == true				
				% Calculate and save the function value for x0 in cache
				% No return is necessary
				fun(x0(1), x0(2), x0(3), 0, 0);
				
			% If no special region is identified, save the average value of the
			% four courners as the value
			else
				fs = [f1, f2, f3, f4];
				favg = mean(fs(~isnan(fs))); % This is to ensure no NaN
				fun(x0(1), x0(2), x0(3), favg, 3);
			end
			
			% No matter what happens, always include the new boxes
			% Save the box of interests
			box_of_interests{counter, 1} = x0;
			box_of_interests{counter, 2} = x1;
			box_of_interests{counter, 3} = x2;
			box_of_interests{counter, 4} = x3;
			box_of_interests{counter, 5} = x4;
			
			% Update the counter
			counter = counter + 1; 	
			
		end
	end
	
	new_box_of_interests = box_of_interests(:,:); 	% Make sure it copies instead
													% of pointing to the same val.
	n_recursion = 0;
	is_clean = false;
    
    while n_recursion < MAX_RECURSION && is_clean == false
	% For each box of interests recursively find a smaller box of interests
	
		box_of_interests = new_box_of_interests(:,:);
		new_counter = 1;
		is_clean = true;
		n_size = size(box_of_interests, 1);
		
        % for every box of interests
		for n = 1 : n_size
		
			% Get the coordinates of the center points and the four corner points
			x0 = box_of_interests{n, 1}; % Center points
			x1 = box_of_interests{n, 2}; % Left top cornor: Clockwise
			x2 = box_of_interests{n, 3};
			x3 = box_of_interests{n, 4};
			x4 = box_of_interests{n, 5}; 
			
			% Proceed only if all the points are in the interested region
			% Get a new_coord_cellgrid of a 3x3 mesh
			new_coord_cellgrid{1, 1} = x0 + (x1 - x0) + (x2 - x0);
			new_coord_cellgrid{1, 2} = x2;
			new_coord_cellgrid{1, 3} = x0 + (x2 - x0) + (x3 - x0);
			new_coord_cellgrid{2, 1} = x1;
			new_coord_cellgrid{2, 2} = x0;
			new_coord_cellgrid{2, 3} = x3;
			new_coord_cellgrid{3, 1} = x0 + (x1 - x0) + (x4 - x0);
			new_coord_cellgrid{3, 2} = x4;
			new_coord_cellgrid{3, 3} = x0 + (x3 - x0) + (x4 - x0);
	
			% New section
			
			fvals = zeros(3, 3);
			for i = 1 : 3
				for j = 1 : 3
					x = new_coord_cellgrid{i, j};
					
					% Many points should have already been calculated
					fval = fun(x(1), x(2), x(3), 0, 1);
					
					fvals(i, j) = fval;
				end
			end

			for i = 1 : 3 - 1
				for j = 1 : 3 - 1
					% fprintf('-> now calculating %d, %d \n', i, j); # DEBUG
					% Four values to send to checker function (clockwise)
					f1 = fvals(i, j);
					f2 = fvals(i, j+1);
					f3 = fvals(i+1, j+1);
					f4 = fvals(i+1, j);
			
					% When a special region is identified
					% Important: the parameters contain NaN sometimes	
					
					% Get the coordinates of the 2x2 mesh (clockwise)
					x1 = new_coord_cellgrid{i, j};
					x2 = new_coord_cellgrid{i, j+1};
					x3 = new_coord_cellgrid{i+1, j+1};
					x4 = new_coord_cellgrid{i+1, j};
					
                    % Get the coordinates of new points based on the center point
                    x0 = (x1 + x2 + x3 + x4) / 4; % Equivalent to x1 + x3 / 2

					
					% Include this condition will give a better estimation
					% as the boundary is not fully included, hence implies
					% a better integration :)
                    %if min(x1) < 0 || max(x1) > 1 || min(x2) < 0 || max(x2) > 1 || min(x3) < 0 || max(x3) > 1 || min(x4) < 0 || max(x4) > 1 
                        % do nothing
                    %else
					if checker(f1, f2, f3, f4) == true
						% Mark the flag
						is_clean = false;
						
						% Calculate and save the function value for x0 in cache
						% No return is necessary
						fun(x0(1), x0(2), x0(3), 0, 0);
					
						% If a region is not of interests, use the average value to represent
						% the center point
					else 
						fs = [f1, f2, f3, f4];
						favg = mean(fs(~isnan(fs))); % This is to ensure no NaN
						fun(x0(1), x0(2), x0(3), favg, 3);
					end
						
						% Save the box of interests
					new_box_of_interests{new_counter, 1} = x0;
					new_box_of_interests{new_counter, 2} = x1;
					new_box_of_interests{new_counter, 3} = x2;
					new_box_of_interests{new_counter, 4} = x3;
					new_box_of_interests{new_counter, 5} = x4;
					
					% Update the counter
					new_counter = new_counter + 1;
				end
			end
		end
		n_recursion = n_recursion + 1;
    end
	
    n_size = size(new_box_of_interests, 1);
    ret = []; % Consider pre-allocate for efficiency
    for n = 1 : n_size
        ret = [ret; new_box_of_interests{n, 1}];
    end
end


% ===========================================================================
% Main algorithm starts here

iter = 0;
old_mesh_size = mesh_size;

while iter < max_recursion
    % 1 - Start to search along z axis for each surface using 2d search
    [X, Y, Z] = coord_meshgrid3D(xmin, xmax, ymin, ymax, zmin, zmax, old_mesh_size);
    cell3d = mesh2cell3D(X, Y, Z);

    cell2ds = subcell(cell3d, 3);

    for i = 1 : old_mesh_size(3)
    % for i = 1 : 1
        cell2d = cell2ds{i};

        % Call old fnction in 2d with recursion limit set to 2
        t_adaptive_search_2D(@f_cached_periodic, cell2d, 1);
    end

    
    % 2 - Start to search along x axis for each surface using 2d search
    % Note that the mesh size is now different since we have more points
    % For more details refer to the write up

    new_mesh_size = [2 * old_mesh_size(1) - 1, old_mesh_size(2), old_mesh_size(3)];
    [X, Y, Z] = coord_meshgrid3D(xmin, xmax, ymin, ymax, zmin, zmax, new_mesh_size);
    cell3d = mesh2cell3D(X, Y, Z);

    cell2ds = subcell(cell3d, 1);

    for i = 1 : new_mesh_size(1)
    % for i = 1 : 1
        cell2d = cell2ds{i};

        % Call old fnction in 2d with recursion limit set to 2
        t_adaptive_search_2D(@f_cached_periodic, cell2d, 1);
    end
    
    % 3 - Update iteration information
    iter = iter + 1;
    
    % 4 - Update new mesh
    old_mesh_size = [new_mesh_size(1), 2*new_mesh_size(2)-1, 2*new_mesh_size(3)-1];
end

all_points = get_all_points();
all_points_keys = all_points.keys();
nkeys = length(all_points_keys);
ret_keys = zeros(nkeys, 3);
ret_vals = zeros(nkeys, 1);

for i = 1: nkeys
    ret_keys(i, :) = str2num(all_points_keys{i});
    ret_vals(i) = all_points(all_points_keys{i});
end

temp = [ret_keys, ret_vals];
temp = sortrows(temp, [1 2 3]);
ret_keys = temp(:, 1:3);
ret_vals = temp(:, 4);

end %end of adaptive search function
