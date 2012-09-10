classdef plane < handle
    %Plane Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        height;
        width;
        vertices;
        bbCorners;
        base;
        side;
        down;
        normal;
        d;
        ratio;
        outimg;
        images = [];
        image_filenames;
        image_masks;
        image_rotations;
        t_cam2world;
        K;
        maxshift = 100;
        blendpx = 100;
        sortVertical = false;
    end
    
    methods
        function obj = load_images(obj)
            n = 1;
            step = 1;
            %if size(obj.image_filenames,1) > 200
            %    step = ceil(size(obj.image_filenames,1) / 200);
            %end
            %for imgnum = 1:step:size(obj.image_filenames,1)
            for imgnum = 1:20
                fprintf('Loading img number %d\tn=%d\tout of %d\n', imgnum,n,size(obj.image_filenames,1));
                r = obj.image_rotations{imgnum};
                t = obj.t_cam2world(imgnum,:)';
                %plane_to_cam = t - obj.base;
                %if(plane_to_cam' * obj.normal) < 0.5
                %    fprintf('Ignoring Bad Image\n');
                %    continue
                %end
                
                rotNorm = -1 * (r * [0;0;1]);
                cam_angle = acosd(dot(rotNorm,obj.normal)/(norm(rotNorm)*norm(obj.normal)));
                
                if cam_angle > 45
                    fprintf('Not Ignoring Bad Image\n');
                    %continue
                end
                
                obj.images = [obj.images plane_img()];
                
                % Load the image and mask
                obj.images(n).img = imread(obj.image_filenames{imgnum});
                obj.images(n).mask = imread(obj.image_masks{imgnum}) > 0;
                m = repmat(obj.images(n).mask,[1,1,3]);
                obj.images(n).img(m==0) = 0;
                % w is actually height, h is width, but the input images are sideways
                chan = size(obj.images(n).img,3);
                assert(chan==3)
                
                % Get the extrinsic matrix
                obj.images(n).r = r;
                obj.images(n).t = t;
                obj.images(n).K = obj.K;
                
                obj.images(n).cam_angle = cam_angle;
                n = n + 1;
            end
        end
        
        function obj = set_tiles_and_rotate(obj)
            for idx = 1:size(obj.images,2)
                fprintf('Projecting image %d\n', idx);
                obj.images(idx) = obj.images(idx).set_tile_and_rotate(obj);
                %imshow(uint8(obj.images(idx).mytile.orig_data));
                %drawnow
            end
        end
        
        function obj = set_tiles_no_rotate(obj)
            for idx = 1:size(obj.images,2)
                fprintf('Projecting image %d\n', idx);
                obj.images(idx) = obj.images(idx).set_tile_no_rotate(obj);
                %imshow(uint8(obj.images(idx).mytile.orig_data));
                %drawnow
            end
        end
        
        function obj = set_tiles_on_plane(obj)
            for idx = 1:size(obj.images,2)
                obj.images(idx) = obj.images(idx).set_tile_on_plane(obj);
            end
        end
        
        function obj = remove_border_pixels(obj)
            for i = 1:size(obj.images,2)
                disp(['removing border pixels for ', num2str(i)]);
                img = obj.images(i).mytile_on_plane.orig_data;
                % mask is one where it's empty, or bordering empty
                mask = sum(img,3) == 0;
                w = size(mask,2);
                h = size(mask,1);
                v_fill = zeros(h,1);
                h_fill = zeros(1,w);
                mask_L = [mask(:,2:w),v_fill];
                mask_R = [v_fill,mask(:,1:w-1)];
                mask_U = [mask(2:h,:);h_fill];
                mask_D = [h_fill;mask(1:h-1,:)];

                mask_1 = mask_L | mask_R | mask_U | mask_D;

                mask_UL = [mask_L(2:h,:);h_fill];
                mask_UR = [mask_R(2:h,:);h_fill];
                mask_DL = [h_fill;mask_L(1:h-1,:)];
                mask_DR = [h_fill;mask_R(1:h-1,:)];

                mask_2 = mask_UL | mask_UR | mask_DL | mask_DR;

                mask = mask | mask_1 | mask_2;
                mask = repmat(mask, [1,1,3]);
                obj.images(i).mytile_on_plane.orig_data(mask) = 0;
            end
        end
        % i'm not confident that the flag is set on all cases we care
        % about, so do more checking here. Obviously needs to be improved.
        function obj = filter_useless(obj)
            useful = false(1,size(obj.images,2));
            for idx = 1:size(obj.images,2)
                if obj.images(idx).useful
                  b = obj.images(idx).mytile_on_plane.cropped_box;
                  if numel(obj.images(idx).mytile_on_plane.orig_valid) > 0 && ...
                      (b.row_max-b.row_min > 0 && b.col_max-b.col_min > 0)
                      useful(idx) = 1;
                  end
                end
            end
            obj.images = obj.images(useful);
        end
        
        
        function obj = fix_intensities(obj)
            avgIntensities = zeros(1,size(obj.images,2));
            for idx = 1:size(obj.images,2)
                gray_img = rgb2gray(uint8(obj.images(idx).mytile_on_plane.orig_data));
                gray_img_linear = reshape(gray_img,[1,numel(gray_img)]);
                gray_img_linear = gray_img_linear(gray_img_linear~=0);
                avgIntensities(idx) = median(double(gray_img_linear));
            end
            avg_overall_intensity = median(avgIntensities);
            for idx = 1:size(obj.images,2)
                gain = avg_overall_intensity/avgIntensities(idx);
                obj.images(idx).mytile_on_plane.orig_data = obj.images(idx).mytile_on_plane.orig_data * gain;
                obj.images(idx).mytile_on_plane.cropped_data = obj.images(idx).mytile_on_plane.cropped_data * gain;
            end
        end
        
        function obj = print_images(obj)
            for idx = 1:size(obj.images,2)
                fprintf('Printing image %d\n', idx);
                obj = obj.print_tile(obj.images(idx).mytile_on_plane);
                imshow(uint8(obj.outimg));
                drawnow
            end
        end
        
        function obj = print_greedy_area(obj)
            % Greedy approximation
            grid = false(obj.height,obj.width);
            cost = 0;
            while(1)
                contribution = zeros(size(obj.images,2));
                for idx = 1:size(obj.images,2)
                    contribution(idx) = obj.images(idx).get_contribution(grid);
                end
                fprintf('contribution sum: %d\n', sum(contribution));
                if(sum(contribution) == 0)
                    break;
                else
                    maxidx = find(contribution == max(contribution),1);
                    cost = cost +  obj.cost_of_tile(obj.images(maxidx).mytile_on_plane);
                    obj = obj.blend_tile(obj.images(maxidx).mytile_on_plane);
                    grid = obj.images(maxidx).update_logical(grid);
                end
            end
            fprintf('cost: %f\n', cost);
        end
        
        
        function obj = print_greedy_cost(obj)
            % First get the avg cost for each image
            node_total_cost = zeros(1,size(obj.images,2));
            node_cost_count = zeros(1,size(obj.images,2));
            node_avg_cost = zeros(1,size(obj.images,2));
            % For each starting image
            for idx1 = 1:size(obj.images,2)
                i1 = obj.images(idx1);
                if(~i1.useful)
                    continue;
                end
                for idx2_i = 1:size(i1.overlap,2)
                    idx2 = i1.overlap(idx2_i);
                    i2 = obj.images(idx2);
                    obj.outimg = zeros(obj.height,obj.width,3);
                    obj = obj.print_tile(i1.mytile_on_plane);
                    cost = obj.cost_of_tile(i2.mytile_on_plane);

                    % End loop if it no longer overlaps
                    if(cost == Inf )
                        fprintf('\n');
                        break
                    else
                        fprintf('Images %d to %d, cost=%f\n', idx1, idx2, cost)
                        node_total_cost(idx1) = node_total_cost(idx1) + cost;
                        node_total_cost(idx2) = node_total_cost(idx2) + cost;
                        node_cost_count(idx1) = node_cost_count(idx1)+1;
                        node_cost_count(idx2) = node_cost_count(idx2)+1;
                    end
                end
            end
            
            for idx = 1:size(obj.images,2)
                if (node_cost_count(idx) ~= 0)
                    node_avg_cost(idx) = node_total_cost(idx)/node_cost_count(idx);
                else
                    node_avg_cost(idx) = 0;
                end
            end
            
            [~, indices] = sort(node_avg_cost);
            grid = false(obj.height,obj.width);
            for idx_i = 1:size(indices,2)
                idx = indices(idx_i);
                if sum(obj.images(idx).get_contribution(grid)) == 0
                    continue;
                end
                obj = obj.blend_minimum_tile(obj.images(idx).mytile_on_plane);
                grid = obj.images(idx).update_logical(grid);
            end
        end
        
        
        
        % debug thing michael used
        function obj = print_greedy_cost_MA(obj)
            % Greedy approximation
            grid = false(obj.height,obj.width);
            cost = 0;
            while(1)
                contribution = zeros(size(obj.images,2));
                costs = zeros(size(obj.images,2));
                for idx = 1:size(obj.images,2)
                    costs(idx) = obj.cost_of_tile(obj.images(idx).mytile_on_plane);
                    contribution(idx) = obj.images(idx).get_contribution(grid);
                end
                fprintf('contribution sum: %d\n', sum(contribution));
                if(sum(contribution) == 0)
                    break;
                else            
                    maxidx = find(contribution == max(contribution),1);
                    cost = cost +  obj.cost_of_tile(obj.images(maxidx).mytile_on_plane);
                    obj = obj.blend_tile(obj.images(maxidx).mytile_on_plane);
                    grid = obj.images(maxidx).update_logical(grid);
                end
            end
            fprintf('cost: %f\n', cost);
        end
        
        function images = greedy_overlap_camera_cost(obj)
            obj = obj.set_overlap(size(obj.images,2));
            % Generate cost DAG
            node_total_cost = zeros(1,size(obj.images,2));
            node_cost_count = zeros(1,size(obj.images,2));
            node_avg_cost = zeros(1,size(obj.images,2));
            % For each starting image
            %for idx1 = 1:size(obj.images,2)
            %    i1 = obj.images(idx1);
            %    for idx2_i = 1:size(i1.overlap,2)
            %        idx2 = i1.overlap(idx2_i);
            %        i2 = obj.images(idx2);
            %        obj.outimg = zeros(obj.height,obj.width,3);
            %        obj = obj.print_tile(i1.mytile_on_plane);
            %        cost = obj.cost_of_tile(i2.mytile_on_plane);

                    % End loop if it no longer overlaps
            %        if(cost == Inf )
            %            keyboard
            %            fprintf('\n');
            %            break
            %        else
            %            fprintf('Images %d to %d, cost=%f\n', idx1, idx2, cost)
            %            node_total_cost(idx1) = node_total_cost(idx1) + cost;
            %            node_total_cost(idx2) = node_total_cost(idx2) + cost;
            %            node_cost_count(idx1) = node_cost_count(idx1)+1;
            %            node_cost_count(idx2) = node_cost_count(idx2)+1;
            %        end
            %    end
            %end
            
            for idx = 1:size(obj.images,2)
                if (node_cost_count(idx) ~= 0)
                    %node_avg_cost(idx) = node_total_cost(idx)/(10000*node_cost_count(idx));
                    node_avg_cost(idx) = node_total_cost(idx)/(10000*node_cost_count(idx));
                else
                    node_avg_cost(idx) = 0;
                end
                node_avg_cost(idx) = node_avg_cost(idx) + ...
                                        obj.images(idx).cam_dist + ...
                                        ((10000/180)*obj.images(idx).cam_angle);
            end
            [~, images] = sort(node_avg_cost);
        end
        
        function images = repeated_shortest_path(obj)
            images = zeros(1,size(obj.images,2));
            images_count = 0;
            obj = obj.setup_DAG();
            obj = obj.set_overlap(size(obj.images,2));
            % Generate cost DAG
            edge_cost = sparse(eye(size(obj.images,2)));
            node_total_cost = zeros(1,size(obj.images,2));
            node_cost_count = zeros(1,size(obj.images,2));
            node_cost = zeros(1,size(obj.images,2));
            % For each starting image
            for idx1 = 1:size(obj.images,2)
                i1 = obj.images(idx1);
                if(~i1.useful) continue; end
                for idx2_i = 1:size(i1.overlap,2)
                    idx2 = i1.overlap(idx2_i);
                    if (idx1 == 1 || idx2 == size(obj.images,2))
                        edge_cost(idx1, idx2) = 1;
                        continue;
                    end
                    i2 = obj.images(idx2);
                    obj.outimg = zeros(obj.height,obj.width,3);
                    cost = obj.cost_of_tiles(i1.mytile_on_plane, i2.mytile_on_plane);
                    
                    % End loop if it no longer overlaps
                    if(cost == Inf )
                        fprintf('\n');
                        break
                    else
                        fprintf('Images %d to %d, cost=%f\n', idx1, idx2, cost)
                        edge_cost(idx1,idx2) = cost;
                        node_total_cost(idx1) = node_total_cost(idx1) + cost;
                        node_total_cost(idx2) = node_total_cost(idx2) + cost;
                        node_cost_count(idx1) = node_cost_count(idx1)+1;
                        node_cost_count(idx2) = node_cost_count(idx2)+1;
                    end
                end
            end
            for idx = 1:size(obj.images,2)
                if (node_cost_count(idx) ~= 0)
                    node_cost(idx) = obj.images(idx).cam_angle^2 * (node_total_cost(idx)/node_cost_count(idx));
                else
                    node_cost(idx) = 0;
                end
            end
            % Ensure graph is connected
            total = sum(sum(edge_cost)) + sum(node_total_cost);
            for idx = 1:size(obj.images,2)-1
                if(edge_cost(idx,idx+1) == 0.0)
                    edge_cost(idx,idx+1) = total;
                end
            end
            %repeatedly solve shortest path problem
            valid_img = zeros(1,size(obj.images,2));
            grid = false(obj.height,obj.width);
            change_made = 1;
            iter = 0;
            while(change_made)
                begin_count = images_count;
                iter = iter + 1;
                change_made = 0;
                % Solve shortest path
                memo = ones(1,size(obj.images,2)) .* Inf;
                path = zeros(1,size(obj.images,2));
                memo(1) = 0;

                % For each node
                for node = 2:size(obj.images,2)
                    % For each node coming in
                    for innode = 1:node-1
                        if(edge_cost(innode,node) ~= 0.0)
                            optimal_cost_in = memo(innode) + edge_cost(innode,node) + node_cost(node);
                            if(optimal_cost_in < memo(node))
                                memo(node) = optimal_cost_in;
                                path(node) = innode;
                            end
                        end
                    end
                end
                % Backtrack through the array
                next_node = size(obj.images,2);
                for node = size(obj.images,2):-1:1
                    if(node == next_node)
                        if valid_img(node) == 0
                            newgrid = obj.images(node).update_logical(grid);
                            if sum(sum(newgrid ~= grid)) > 0
                                change_made = true;
                                grid = newgrid;
                                valid_img(node) = iter;
                                %adjust for "fake" nodes created by
                                %setup_DAG()
                                if (node ~= 1 && node ~= size(obj.images,2))
                                    images_count = images_count+1;
                                    images(images_count) = node-1;
                                end
                            end
                        end
                        next_node = path(node);
                        %discourage picking this path next time
                        if next_node ~= 0
                            edge_cost(next_node, node) = total+1;
                        end
                    end
                end
                if images_count > begin_count+1
                    images(begin_count+1:images_count) = sort(images(begin_count+1:images_count));
                end
            end
            obj.images = obj.images(2:size(obj.images,2)-1);
            obj.outimg = zeros(obj.height,obj.width,3);
            images = images(1:images_count);
        end
        
        
        function [fullCandidates, partialCandidates] = getCandidateImages(obj, section, imageIndices, maxAngle)
            fullIndices = false(1,size(imageIndices,2));
            partialIndices = false(1,size(imageIndices,2));
            %if we have no candidates, use partials, which only partially
            %fill the section
            for i = 1:size(imageIndices,2)
                if imageIndices(i) == 0
                    continue
                end
                currImage = obj.images(imageIndices(i));
                box = currImage.mytile_on_plane.orig_box;
                data = currImage.mytile_on_plane.orig_data;
                if section.row_max < box.row_min || section.row_min > box.row_max || ...
                        section.col_max < box.col_min || section.col_min > box.col_max
                    continue
                end
                y_min_offset = section.row_min - box.row_min;
                y_max_offset = section.row_max - box.row_min;
                x_min_offset = section.col_min - box.col_min;
                x_max_offset = section.col_max - box.col_min;
                y_min_source = max(1,min(box.row_max-box.row_min+1, y_min_offset + 1));
                y_max_source = max(1,min(box.row_max-box.row_min+1, y_max_offset + 1));
                x_min_source = max(1,min(box.col_max-box.col_min+1, x_min_offset + 1));
                x_max_source = max(1,min(box.col_max-box.col_min+1, x_max_offset + 1));
                
                if sum(data(y_min_source:y_max_source,x_min_source:x_max_source,:)) == 0
                    continue
                end
                section_center_world = obj.get_world_pts([(section.row_max+section.row_min)/2;(section.col_max+section.col_min)/2]);
                cam_to_section_center = section_center_world - currImage.t;
                cam_to_section_center = cam_to_section_center/norm(cam_to_section_center);
                cameraDirection = currImage.r * [0;0;1];
                cameraDirection = cameraDirection/norm(cameraDirection);
                angleBetween = acos(dot(cameraDirection, cam_to_section_center)) * (180/pi);
                if angleBetween > 180
                    keyboard
                end
                if angleBetween > maxAngle
                    continue
                end
                
               if sum(data(y_min_source,x_min_source,:)) == 0 || sum(data(y_min_source,x_max_source,:)) == 0 || ... 
                       sum(data(y_max_source,x_min_source,:)) == 0 || sum(data(y_max_source,x_max_source,:)) == 0;
                   partialIndices(i) = 1;
               else
                   fullIndices(i) = 1;
               end
            end
            fullCandidates = imageIndices(fullIndices);
            partialCandidates = imageIndices(partialIndices);
        end
        
        function [obj, section] = textureWithBestImage(obj, origSection, imageIndices)
            section = origSection;
            bestScore = 0;
            for i = 1:size(imageIndices,2)
                currImage = obj.images(imageIndices(i));
                cameraDirection = -1 * (currImage.r * [0;0;1]);
                cosineValue = dot(cameraDirection,obj.normal);
                section_center_world = obj.get_world_pts([(section.row_max+section.row_min)/2;(section.col_max+section.col_min)/2]);
                distToCamera = norm(currImage.t - section_center_world);
                score = (1/distToCamera) * cosineValue;
                if (score > bestScore) || section.bestImage == 0
                    bestScore = score;
                    section.bestImage = imageIndices(i);
                end
            end
            if section.bestImage <= 0
                return
            end
            bestImage = obj.images(section.bestImage);
            box = bestImage.mytile_on_plane.orig_box;
            sourceData = bestImage.mytile_on_plane.orig_data;
            newData = zeros(section.row_max-section.row_min+1,...
                section.col_max-section.col_min+1,3);
            
            y_min_offset = section.row_min - box.row_min;
            y_max_offset = section.row_max - box.row_min;
            x_min_offset = section.col_min - box.col_min;
            x_max_offset = section.col_max - box.col_min;
            y_min_source = max(1,min(box.row_max-box.row_min+1, y_min_offset + 1));
            y_max_source = max(1,min(box.row_max-box.row_min+1, y_max_offset + 1));
            x_min_source = max(1,min(box.col_max-box.col_min+1, x_min_offset + 1));
            x_max_source = max(1,min(box.col_max-box.col_min+1, x_max_offset + 1));
            y_min_new = 1 + (-1 * min(0, y_min_offset));
            y_max_new = 1 + (section.row_max-section.row_min) - max(0, section.row_max - box.row_max);
            x_min_new = 1 + (-1 * min(0, x_min_offset));
            x_max_new = 1 + (section.col_max-section.col_min) - max(0, section.col_max - box.col_max);
            newData(y_min_new:y_max_new,x_min_new:x_max_new,:) = ...
                sourceData(y_min_source:y_max_source,x_min_source:x_max_source,:);
            section_tile = tile();
            section_tile.cropped_box = section;
            section_tile.cropped_data = newData;
            obj = obj.blend_tile(section_tile);
        end
        
        function [obj, section] = textureWithSelectedImages(obj, origSection, imageIndices)
            section = origSection;
            for i = 1:size(imageIndices,2)
                newData = zeros(section.row_max-section.row_min+1,...
                    section.col_max-section.col_min+1,3);

                currImage = obj.images(imageIndices(i));
                box = currImage.mytile_on_plane.orig_box;
                sourceData = currImage.mytile_on_plane.orig_data;

                
                y_min_offset = section.row_min - box.row_min;
                y_max_offset = section.row_max - box.row_min;
                x_min_offset = section.col_min - box.col_min;
                x_max_offset = section.col_max - box.col_min;
                y_min_source = max(1,min(box.row_max-box.row_min+1, y_min_offset + 1));
                y_max_source = max(1,min(box.row_max-box.row_min+1, y_max_offset + 1));
                x_min_source = max(1,min(box.col_max-box.col_min+1, x_min_offset + 1));
                x_max_source = max(1,min(box.col_max-box.col_min+1, x_max_offset + 1));
                y_min_new = 1 + (-1 * min(0, y_min_offset));
                y_max_new = 1 + (section.row_max-section.row_min) - max(0, section.row_max - box.row_max);
                x_min_new = 1 + (-1 * min(0, x_min_offset));
                x_max_new = 1 + (section.col_max-section.col_min) - max(0, section.col_max - box.col_max);
                newData(y_min_new:y_max_new,x_min_new:x_max_new,:) = ...
                    sourceData(y_min_source:y_max_source,x_min_source:x_max_source,:);
                section_tile = tile();
                section_tile.cropped_box = section;
                section_tile.cropped_data = newData;
                obj = obj.blend_tile(section_tile);
                
                
            end
        end
        
        %Approximation of Stewart's method
        function obj = split_plane_texturing(obj, step, blend, maxCacheAngle, maxAngle)
            step = step-1;
            numSectionsX = ceil(obj.width/step);
            numSectionsY = ceil(obj.height/step);
            %first create lots of rectangular sections
            s.row_min = -1;
            s.row_max = -1;
            s.col_min = -1;
            s.col_max = -1;
            s.bestImage = -1;
            sections = repmat(s, 1, ((numSectionsX) * (numSectionsY)));
            stepEndRow = obj.height;
            if mod(obj.height,step) ~= 0
                stepEndRow = stepEndRow + step - mod(obj.height,step);
            end
            stepEndCol = obj.width;
            if mod(obj.width,step) ~= 0
                stepEndCol = stepEndCol + step - mod(obj.width,step);
            end
            i = 1;
            for row_min = 1:step:stepEndRow
                disp(['creating tile row ', num2str(row_min), ' out of ', num2str(obj.height)]);
                row_max = min(row_min+step,obj.height);
                for col_min = 1:step:stepEndCol
                    col_max = min(col_min+step, obj.width);
                    sections(i).row_min = max(1,row_min-blend);
                    sections(i).row_max = min(obj.height,row_max+blend);
                    sections(i).col_min = max(1,col_min-blend);
                    sections(i).col_max = min(obj.width,col_max+blend);
                    sections(i).bestImage = 0;
                    i = i + 1;
                end
            end
            %spatial index of where each section is
            sectionGrid = reshape((1:size(sections,2)),numSectionsY,numSectionsX);
            for i = 1:size(sectionGrid,1)
                disp(['texturing tile row ', num2str(i), ' out of ', num2str(size(sectionGrid,1))]);
                for j = 1:size(sectionGrid,2)
                    UImage = 0;
                    LImage = 0;
                    ULImage = 0;
                    %URImage = 0;
                    if i > 1
                        UImage = sections(sectionGrid(i-1,j)).bestImage;
                    end
                    if j > 1
                        LImage = sections(sectionGrid(i,j-1)).bestImage;
                    end
                    if (i > 1) && (j > 1)
                        ULImage = sections(sectionGrid(i-1,j-1)).bestImage;
                    end
                    %in testing this seemed to not help or be worse - but
                    %don't have a good reason
                    %if (i > 1) && (j < size(sectionGrid,2))
                    %    URImage = sections(sectionGrid(i-1,j+1)).bestImage;
                    %end
                    [fullCacheCandidates,~] = obj.getCandidateImages(sections(sectionGrid(i,j)), [UImage,LImage,ULImage], maxCacheAngle);
                    if ~isempty(fullCacheCandidates)
                        [obj, s] = obj.textureWithBestImage(sections(sectionGrid(i,j)), fullCacheCandidates);
                    else
                        [fullCandidates, partialCandidates] = obj.getCandidateImages(sections(sectionGrid(i,j)), (1:size(obj.images,2)), maxAngle);
                        if ~isempty(fullCandidates)
                            [obj, s] = obj.textureWithBestImage(sections(sectionGrid(i,j)), fullCandidates);
                        else
                            [obj, s] = obj.textureWithSelectedImages(sections(sectionGrid(i,j)), partialCandidates);
                        end
                    end
                    if s.bestImage == 0
                        continue
                    else
                        sections(sectionGrid(i,j)) = s;
                    end
                end
            end
        end
        
        function MST_prim(obj)
            %create nodes, covering nodes ~= covering the plane
            step = 10;
            
            n.row = -1;
            n.col = -1;
            n.images = [];
            n.covered = false;
            nodes = repmat(n, 1, ceil(obj.height/step) * ceil(obj.width/step));
            validNodes = zeros(1,size(nodes,2));
            k = 1;
            for i = 1:step:obj.height
                for j = 1:step:obj.width
                    nodes(k).row = i;
                    nodes(k).col = j;
                    nodes(k).images = [];
                    nodes(k).covered = false;
                    for im = 1:size(obj.images,2)
                        data = obj.images(im).mytile_on_plane.orig_data;
                        box = obj.images(im).mytile_on_plane.orig_box;
                        dataY = (i-box.row_min+1);
                        dataX = (j-box.col_min+1);
                        if dataY >= 1 && dataY <= (box.row_max-box.row_min+1) && ...
                           dataX >= 1 && dataX <= (box.col_max-box.col_min+1) && ...
                               sum(data(dataY,dataX,:)) ~= 0
                            nodes(k).images = [nodes(k).images, im];
                            obj.images(im).nodes = [obj.images(im).nodes, nodes(k)];
                        end
                    end
                    if size(currNode.images,2) ~= 0
                      validNodes(k) = 1;
                    end
                    k = k + 1;
                end
            end
            nodes = nodes(validNodes);
            
            %need to account for more overlaps in 2D scenario, also more
            %edge costs
            %everything past here isn't done
            
            
            %get starting image, also list of images to work with
            candidateImages = ones(size(obj.images,2));
            obj = obj.set_overlap(size(obj.images,2));
            
            % Generate cost DAG
            node_total_cost = zeros(1,size(obj.images,2));
            node_cost_count = zeros(1,size(obj.images,2));
            node_avg_cost = zeros(1,size(obj.images,2));
            % For each starting image
            for idx1 = 1:size(obj.images,2)
                i1 = obj.images(idx1);
                for idx2_i = 1:size(i1.overlap,2)
                    idx2 = i1.overlap(idx2_i);
                    i2 = obj.images(idx2);
                    obj.outimg = zeros(obj.height,obj.width,3);
                    obj = obj.print_tile(i1.mytile_on_plane);
                    cost = obj.cost_of_tile(i2.mytile_on_plane);

                    % End loop if it no longer overlaps
                    if(cost == Inf )
                        keyboard
                        fprintf('\n');
                        break
                    else
                        fprintf('Images %d to %d, cost=%f\n', idx1, idx2, cost)
                        node_total_cost(idx1) = node_total_cost(idx1) + cost;
                        node_total_cost(idx2) = node_total_cost(idx2) + cost;
                        node_cost_count(idx1) = node_cost_count(idx1)+1;
                        node_cost_count(idx2) = node_cost_count(idx2)+1;
                    end
                end
            end
            
            for idx = 1:size(obj.images,2)
                if (node_cost_count(idx) ~= 0)
                    node_avg_cost(idx) = node_total_cost(idx)/node_cost_count(idx);
                else
                    candidateImages(idx) = 0;
                    node_avg_cost(idx) = Inf;
                    obj.blend_uncropped_tile(obj.images(idx).mytile_on_plane);
                    for n = 1:size(obj.images(idx).nodes,2)
                        obj.images(idx).nodes(n).covered = true;
                    end
                end
            end
            
            %candidateImages is now 1 for each image that is still worth
            %looking at.
            [minAvg, startInd] = min(node_avg_cost);
            
            candidateImages(startInd) = 0;
            obj.blend_uncropped_tile(obj.images(startInd).mytile_on_plane);
            for n = 1:size(obj.images(startInd).nodes,2)
                obj.images(startInd).nodes(n).covered = true;
            end
            
            %now we can start main loop
            %not written yet
            prevSum = 0;
            while sum(candidateImages) ~= 0
                if sum(candidateImages) == prevSum
                    keyboard
                end
                prevSum = sum(candidateImages);
                overlap_costs = Inf(1,size(candidateImages,2));
                foundOverlap = false;
                for i = 1:size(candidateImages,2)
                    if candidateImages(i) == 0
                        continue
                    end
                    currImage = obj.images(i);
                    has_uncovered_nodes = false;
                    has_covered_nodes = false;
                    for n = 1:size(currImage.nodes,2)
                        if currImage.nodes(n).covered
                            has_covered_nodes = true;
                        else
                            has_uncovered_nodes = true;
                        end
                        if has_covered_nodes && has_uncovered_nodes
                            break;
                        end
                    end
                    if ~has_uncovered_nodes
                        %this image adds nothing new, discard it
                        continue
                    end
                    if ~has_covered_nodes
                        %this image is completely disjoint from current
                        %texturing, save for later
                        candidateImages(i) = 0;
                        continue
                    end
                    foundOverlap = true;
                    %image has some overlap, but also textures some new
                    %area
                    overlap_costs(i) = obj.cost_of_tile(currImage.mytile_on_plane);    
                end
                
                if ~foundOverlap
                    keyboard
                end
                [minCost, minInd] = min(overlap_costs);
                obj.blend_uncropped_tile(obj.images(minInd).mytile_on_plane);
                for n = 1:size(obj.images(minInd).nodes,2)
                    obj.images(minInd).nodes(n).covered = true;
                end
                candidateImages(minInd) = 0;
            end
        end        
        
        
        
        function obj = native_blending(obj, images)
            for i = 1:size(images,2)
                idx = images(i);
                A = obj.outimg;
                B = obj.outimg;
                B(obj.images(idx).mytile_on_plane.orig_box.row_min:obj.images(idx).mytile_on_plane.orig_box.row_max, ...
                    obj.images(idx).mytile_on_plane.orig_box.col_min:obj.images(idx).mytile_on_plane.orig_box.col_max, :) = ...
                    obj.images(idx).mytile_on_plane.orig_data;
                O = zeros(size(A,1),size(A,2));
                O(sum(A,3) == 0) = 1;
                O(logical((sum(A,3) ~= 0) .* (sum(B,3) ~= 0))) = (1 / (idx+1));
                H = vision.AlphaBlender('Operation', 'Blend', 'Opacity', O);
                obj.outimg = step(H, A, B);
            end     
        end
        
        function obj = painters_algorithm(obj, images)
            for i = size(images):-1:1
                idx = images(i);
                obj = obj.blend_tile_painter(obj.images(idx).mytile_on_plane);
            end
        end

        function obj = print_selected_images(obj, images)
            for i = 1:size(images,2)
                idx = images(i);
                obj = obj.print_tile(obj.images(idx).mytile_on_plane);
                imshow(uint8(obj.outimg));
                drawnow
            end
        end
        
        function obj = print_selected_images_crop(obj, images)
            for i = 1:size(images,2)
                idx = images(i);
                obj = obj.print_tile_crop(obj.images(idx).mytile_on_plane);
                imshow(uint8(obj.outimg));
                drawnow
            end
        end

        function obj = minimum_blending(obj, images)
            for i = 1:size(images,2)
                idx = images(i);
                filled = sum(obj.outimg,3) ~= 0;
                if (sum(sum(filled)) == (size(obj.outimg,1) * size(obj.outimg,2)))
                    return
                end
                disp(['min blending tile ', num2str(idx)]);
                obj = obj.blend_minimum_tile(obj.images(idx).mytile_on_plane);
            end
            filled = sum(obj.outimg,3) ~= 0;
            if (sum(sum(filled)) == (size(obj.outimg,1) * size(obj.outimg,2)))
                return
            end
            obj = obj.blend_uncropped_pieces(images);
        end
            
        
        % use portions of chosen images that were previously cropped out
        % due to not being rectangular.
        function obj = blend_uncropped_pieces(obj, images)
            for i = 1:size(images,2)
                idx = images(i);
                disp(['uncropped blending tile ', num2str(idx)]);
                obj = obj.blend_uncropped_tile(obj.images(idx).mytile_on_plane);
            end
        end
        
        
        
        function obj = fill_holes(obj)
            for i = round(size(obj.outimg,1)/2):-1:2
                start = 0;
                for j = 1:size(obj.outimg,2)
                    if sum(obj.outimg(i,j,:)) == 0 && start ==0
                        start = j;
                    elseif (sum(obj.outimg(i,j,:)) ~= 0 || (j == size(obj.outimg,2))) && start ~= 0
                        finish = j;
                        alpha = repmat(((start:finish)-start)/(finish-start),[1,1,3]);
                        bottomVal = mean(obj.outimg(i+30:i-1,start:finish,:),1);
                        if start == 1
                            leftVal = bottomVal;
                        else
                            leftStart = max(1,start-30);
                            leftVal = mean(obj.outimg(i,leftStart:start-1,:),2);
                            leftVal = repmat(leftVal,[1,(finish-start+1),1]);
                        end
                        if finish == size(obj.outimg,2)
                            rightVal = bottomVal;
                        else
                            rightFinish = min(size(obj.outimg,2),finish+30);
                            rightVal = mean(obj.outimg(i,finish+1:rightFinish,:),2);
                            rightVal = repmat(rightVal,[1,(finish-start+1),1]);
                        end
                        vals = (alpha.*rightVal + (1-alpha).*leftVal)/2 + bottomVal/2;
                        obj.outimg(i,start:finish,:) = vals;
                    end
                end
            end    
            for i = round(size(obj.outimg,1)/2):size(obj.outimg,1)-1
                start = 0;
                for j = 1:size(obj.outimg,2)
                    %if sum(obj.outimg(i+1,j,:)) == 0
                    %    samples = obj.outimg(max(1,i-10):i-1,j,:);
                    %    keyboard
                    %    %samples = [samples; obj.outimg(i,max(1,j-10):j-1,:)];
                    %    obj.outimg(i,j,:) = mean(samples);
                    if sum(obj.outimg(i,j,:)) == 0 && start ==0
                        start = j;
                    elseif (sum(obj.outimg(i,j,:)) ~= 0 || (j == size(obj.outimg,2))) && start ~= 0
                        finish = j;
                        alpha = repmat(((start:finish)-start)/(finish-start),[1,1,3]);
                        topVal = mean(obj.outimg(i-30:i-1,start:finish,:),1);
                        if start == 1
                            leftVal = topVal;
                        else
                            leftStart = max(1,start-30);
                            leftVal = mean(obj.outimg(i,leftStart:start-1,:),2);
                            leftVal = repmat(leftVal,[1,(finish-start+1),1]);
                        end
                        if finish == size(obj.outimg,2)
                            rightVal = topVal;
                        else
                            rightFinish = min(size(obj.outimg,2),finish+30);
                            rightVal = mean(obj.outimg(i,finish+1:rightFinish,:),2);
                            rightVal = repmat(rightVal,[1,(finish-start+1),1]);
                        end
                        vals = (alpha.*rightVal + (1-alpha).*leftVal)/2 + topVal/2;
                        obj.outimg(i,start:finish,:) = vals;
                    %    leftVal = mean(obj.outimg(i,max(1,start-10):start,:));
                    %    leftVal = repmat(leftVal,[1,finish-start+1]);
                    %    rightVal = mean(obj.outimg(i,finish:min(size(obj.outimg,2),finish+10),:));
                    %    rightVal = repmat(rightVal,[1,finish-start+1]);
                    %    k = start:finish;
                    %    topVal = (obj.outimg(max(size(obj.outimg,1),i-10),k,:));
                    %    alpha = (k-start)/(finish-start);
                    %    alpha = repmat(alpha,[1,1,3]);
                    %    obj.outimg(i,start:finish,:) = alpha .* rightVal + (1-alpha) .* leftVal;
                    %    start = 0;
                    end
                end
            end
        end
        
        function plane_pts = get_plane_pts(obj, box)
            [jj ii] = meshgrid(box.col_min:box.col_max, ...
                box.row_min:box.row_max);
            npoints = numel(ii);
            ivec = reshape(ii, [1,npoints]);
            jvec = reshape(jj, [1,npoints]);
            plane_pts = [ivec ; jvec];
        end
        
        
        function world_pts = get_world_pts(obj, plane_pts)
            npoints = size(plane_pts,2);
            world_pts = repmat(obj.base, [1,npoints]);
            world_pts = world_pts + ...
                repmat(plane_pts(1,:) / obj.height, [3,1]) .* ...
                repmat(obj.down, [1, npoints]);
            world_pts = world_pts + ...
                repmat(plane_pts(2,:) / obj.width, [3,1]) .* ...
                repmat(obj.side, [1, npoints]);
        end
        
        
        function closest_point = get_closest_plane_point(obj, cam_pt)
            world_pt = cam_pt - ...
                ((cam_pt - obj.base)'*obj.normal)*obj.normal;
            corner_vec = world_pt - obj.base;
            vert = norm(corner_vec'*(obj.down / norm(obj.down)))/norm(obj.down);
            horiz = norm(corner_vec'*(obj.side / norm(obj.side)))/norm(obj.side);
            closest_point = round([vert * obj.height ; horiz * obj.width]);
        end
        
        function obj = sort_images(obj)
            closest_points = zeros(2,size(obj.images,2));
            for idx = 1:size(obj.images,2)
                closest_points(:,idx) = ...
                    obj.get_closest_plane_point(obj.images(idx).t);
            end
            vrange = max(closest_points(1,:)) - min(closest_points(1,:));
            hrange = max(closest_points(2,:)) - min(closest_points(2,:));
            if(vrange > hrange)
                obj.sortVertical = true;
                [~, I] = sort(closest_points(1,:));
            else
                [~, I] = sort(closest_points(2,:));
            end
            obj.images = obj.images(I);
        end
        
        function obj = sort_images2(obj)
            left = zeros(1,size(obj.images,2));
            top = zeros(1,size(obj.images,2));
            for idx = 1:size(obj.images,2)
                left(idx) = obj.images(idx).mytile_on_plane.orig_box.col_min;
                top(idx) = obj.images(idx).mytile_on_plane.orig_box.row_min;
            end
            hrange = max(left) - min(left);
            vrange = max(top) - min(top);
            if (vrange > hrange)
                obj.sortVertical = true;
                [~, I] = sort(top(1,:));
            else
                [~, I] = sort(left(1,:));
            end
            obj.images = obj.images(I);
        end
        
        function box = get_camera_box(obj, cam_pt, radius_in_cm)
            closest_point = obj.get_closest_plane_point(cam_pt);
            radius_pixels = obj.ratio * radius_in_cm;
            box.row_min = closest_point(1) - radius_pixels;
            box.row_max = closest_point(1) + radius_pixels;
            box.col_min = closest_point(2) - radius_pixels;
            box.col_max = closest_point(2) + radius_pixels;
        end
       
        
        function cost = cost_of_tiles(obj, t1, t2)
            box = t1.orig_box;
            tempImg = obj.outimg;
            tempImg(:,:,:) = 0;
            tempImg(box.row_min:box.row_max,box.col_min:box.col_max,:) = t1.orig_data;            
            [~,~, c] = size(tempImg);
            box = t2.orig_box;
            existing_tile = tempImg(box.row_min:box.row_max,...
                                        box.col_min:box.col_max,:);
            existing_mask = sum(existing_tile,3) > 0;
            added_tile = t2.orig_data;
            %added_mask = t.border_mask;
            ssd = 0;
            for chan = 1:c
                ssd = ssd + sum(sum((existing_tile(:,:,chan) - ...
                                    added_tile(:,:,chan)).^2 .* ...
                                    existing_mask));
            end
            cost = ssd;
        end
        
        function cost = cost_of_tile(obj, t)
            [~,~, c] = size(obj.outimg);
            box = t.orig_box;
            existing_tile = obj.outimg(box.row_min:box.row_max,...
                                        box.col_min:box.col_max,:);
            existing_mask = sum(existing_tile,3) > 0;
            added_tile = t.orig_data;
            %added_mask = t.border_mask;
            ssd = 0;
            for chan = 1:c
                ssd = ssd + sum(sum((existing_tile(:,:,chan) - ...
                                    added_tile(:,:,chan)).^2 .* ...
                                    existing_mask));
            end
            cost = ssd;
        end
        
        
        function obj = print_tile(obj, t)
            box = t.orig_box;
            ii = 1;
            for i=box.row_min:box.row_max
                jj =1;
                for j=box.col_min:box.col_max
                    if(sum(obj.outimg(i,j,:),3)==0 && ...
                       sum(t.orig_data(ii,jj,:))~=0);
                        obj.outimg(i,j,:) = t.orig_data(ii,jj,:);
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
        
        function obj = print_tile_over_crop(obj, t)
            box = t.cropped_box;
            ii = 1;
            for i=box.row_min:box.row_max-1
                jj =1;
                for j=box.col_min:box.col_max-1
                    if sum(t.cropped_data(ii,jj,:))~=0
                        obj.outimg(i,j,:) = t.cropped_data(ii,jj,:);
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end        
        function obj = print_tile_crop(obj, t)
            box = t.cropped_box;
            ii = 1;
            for i=box.row_min:box.row_max-1
                jj =1;
                for j=box.col_min:box.col_max-1
                    if(sum(obj.outimg(i,j,:),3)==0 && ...
                       sum(t.cropped_data(ii,jj,:))~=0 && sum(t.cropped_data(ii+1,jj+1,:)) ~= 0);
                        obj.outimg(i,j,:) = t.cropped_data(ii,jj,:);
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
        
        function obj = print_uncropped_tile(obj, t, grid)
            box = t.orig_box;
            ii = 1;
            for i=box.row_min:box.row_max-1
                jj =1;
                for j=box.col_min:box.col_max-1
                    if(sum(obj.outimg(i,j,:),3)==0 && ...
                       sum(t.orig_data(ii,jj,:))~=0 && sum(t.orig_data(ii+1,jj+1,:)) ~= 0);
                        obj.outimg(i,j,:) = t.orig_data(ii,jj,:);
                        grid(i,j) = 1;
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
        
        
        function obj = blend_uncropped_tile(obj, t)
            box = t.orig_box;
            
            fillArea = obj.outimg(box.row_min:box.row_max,box.col_min:box.col_max,:);
            filled = sum(fillArea,3) ~= 0;
            newFill = (sum(t.orig_data,3) ~= 0) & ~filled;
            if (sum(sum(newFill)) == 0)
                return
            end
                
                
                
            % mask is one where it's empty
            mask = sum(t.orig_data,3) == 0;
            ii = 1;
            for i=box.row_min:box.row_max
                jj = 1;
                for j=box.col_min:box.col_max
                    if sum(t.orig_data(ii,jj,:),3) ~= 0
                        if(sum(obj.outimg(i,j,:),3)~=0)
                            % find the closest empty pixel (manhattan dist)
                            mask_row = mask(ii,:);
                            mask_col = mask(:,jj);
                            left_dist = (jj - find(mask_row(1:jj)));
                            right_dist = find(mask_row(jj:end));
                            up_dist = (ii - find(mask_col(1:ii)));
                            down_dist = find(mask_col(ii:end));
                            mindist = min([left_dist, right_dist, rot90(up_dist), rot90(down_dist), obj.blendpx]);
                            %mindist = min([ii,box.row_max-i,...
                            %    jj,box.col_max-j,...
                            %    obj.blendpx]);
                            alpha = mindist/obj.blendpx;
                            obj.outimg(i,j,:) = ...
                                t.orig_data(ii,jj,:)*alpha +...
                                obj.outimg(i,j,:)*(1-alpha);
                        else
                            obj.outimg(i,j,:) = t.orig_data(ii,jj,:);
                        end
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
                    
        function obj = blend_tile(obj, t)
            box = t.cropped_box;
            newData = t.cropped_data;
            LR_half_increase = 1:floor((box.col_max-box.col_min+1)/2);
            if (mod(box.col_max-box.col_min+1,2))==1;
                distRow = [LR_half_increase,LR_half_increase(end)+1,fliplr(LR_half_increase)];
            else
                distRow = [LR_half_increase, fliplr(LR_half_increase)];
            end;
            LR_distMat = repmat(distRow,[box.row_max-box.row_min+1,1]);
            UD_half_increase= (1:floor((box.row_max-box.row_min+1)/2))';
            if (mod(box.row_max-box.row_min+1,2))==1;
                distCol = [UD_half_increase;UD_half_increase(end)+1;flipud(UD_half_increase)];
            else
                distCol = [UD_half_increase; flipud(UD_half_increase)];
            end;
            UD_distMat = repmat(distCol, [1, box.col_max-box.col_min+1]);
            maxBlendpx = repmat(obj.blendpx, [box.row_max-box.row_min+1, box.col_max-box.col_min+1]);
            minDistMat = min(LR_distMat,UD_distMat);
            alphaMat = min((minDistMat ./ maxBlendpx),1);
            oldData = obj.outimg(box.row_min:box.row_max,box.col_min:box.col_max,:);
            oldDataEmpty = sum(oldData,3) == 0;
            alphaMat(oldDataEmpty) = 1;
            newDataEmpty = sum(newData,3) == 0;
            alphaMat(newDataEmpty) = 0;
            alphaMat = repmat(alphaMat, [1,1,3]);
            obj.outimg(box.row_min:box.row_max,box.col_min:box.col_max,:) = ((1-alphaMat) .* oldData) + (alphaMat .* newData);
        end
        
        %slow way of doing it, but more readable. Same thing happens in new
        %way
        function obj = blend_tile_old(obj, t)
            box = t.cropped_box;
            ii = 1;
            for i=box.row_min:box.row_max
                jj = 1;
                for j=box.col_min:box.col_max
                    if(sum(t.cropped_data(ii,jj,:)) == 0)
                        jj = jj+1;
                        continue
                    end
                    if(sum(obj.outimg(i,j,:),3)~=0)
                        mindist = min([ii,box.row_max-i,...
                            jj,box.col_max-j,...
                            obj.blendpx]);
                        alpha = mindist/obj.blendpx;
                        obj.outimg(i,j,:) = ...
                            t.cropped_data(ii,jj,:)*alpha +...
                            obj.outimg(i,j,:)*(1-alpha);
                    else
                        obj.outimg(i,j,:) = t.cropped_data(ii,jj,:);
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
        
        %placeholder, if we do this route in the future, simply don't do
        %blending if the edge goes to the edge of the plane.
        function obj = blend_tile_painter(obj, t)
            box = t.box;
            ii = 1;
            for i=box.row_min:box.row_max
                jj = 1;
                for j=box.col_min:box.col_max
                    if(sum(obj.outimg(i,j,:),3)~=0)
                        mindist = min([ii,box.row_max-i,...
                            jj,box.col_max-j,...
                            obj.blendpx]);
                        alpha = mindist/obj.blendpx;
                        obj.outimg(i,j,:) = ...
                            t.data(ii,jj,:)*alpha +...
                            obj.outimg(i,j,:)*(1-alpha);
                    else
                        obj.outimg(i,j,:) = t.data(ii,jj,:);
                    end
                    jj = jj+1;
                end
                ii = ii+1;
            end
        end
        
        
        function obj = blend_minimum_tile(obj, t)
            box = t.cropped_box;
            
            
            % work with a local copy so we can track boxes and not deal
            % with 3 channels
            pixelGrid = sum(obj.outimg,3);
            
            foundHoles = [];
            
            currHole = box();
            currHole.row_min = 0;
            currHole.row_max = 0;
            currHole.col_min = 0;
            currHole.col_max = 0;
            
            for i=box.row_min:box.row_max
                for j = box.col_min:box.col_max
                    % we found an empty pixel, no col_min set yet
                    if((currHole.col_min == 0) && (pixelGrid(i,j) == 0))
                        currHole.row_min = i;
                        currHole.col_min = j;
                    end
                    % we found a filled pixel on the same row and we have col_min
                    % or we are at end of row without finding col_max
                    if ((currHole.col_min ~= 0) && (i == currHole.row_min) && ...
                            ((pixelGrid(i,j)~= 0) || (j == box.col_max)))
                        if pixelGrid(i,j)~=0
                            currHole.col_max = j-1;
                        else
                            currHole.col_max = j;
                        end
                        
                        
                        % Now see how many rows down this set up empty
                        % pixels goes
                        for ii = currHole.row_min:box.row_max
                            if (sum(pixelGrid(ii,currHole.col_min:currHole.col_max) ~= 0) ...
                                    || (ii == box.row_max))
                                if (sum(pixelGrid(ii,currHole.col_min:currHole.col_max) ~= 0))
                                    currHole.row_max = ii-1;
                                else
                                    currHole.row_max = ii;
                                end
                                break;
                            end
                        end
                        
                        % sanity check
                        if (currHole.row_min == 0 || currHole.row_max == 0 ...
                                || currHole.col_min == 0 || currHole.col_max == 0)
                            keyboard;
                        end
                        
                        % save hole, set up next one
                        pixelGrid(currHole.row_min:currHole.row_max,currHole.col_min:currHole.col_max) = ...
                            ones(currHole.row_max-currHole.row_min+1,currHole.col_max-currHole.col_min+1);
                        foundHoles = [foundHoles currHole];
                        currHole = box();
                        currHole.row_min = 0;
                        currHole.row_max = 0;
                        currHole.col_min = 0;
                        currHole.col_max = 0;
                    end
                end
            end
            
            p = box();
            patches = repmat(p,1,size(foundHoles,2));
            %here we expand the hole size to accomodate blending
            for h = 1:size(foundHoles,2)
                %newPatch = box();
                patches(h).row_min = max(box.row_min,foundHoles(h).row_min-obj.blendpx);
                patches(h).row_max = min(box.row_max,foundHoles(h).row_max+obj.blendpx);
                patches(h).col_min = max(box.col_min,foundHoles(h).col_min-obj.blendpx);
                patches(h).col_max = min(box.col_max,foundHoles(h).col_max+obj.blendpx);
                %patches = [patches newPatch];
            end
            % paste and blend now
            for h = 1:size(patches,2)
                patch = patches(h);
                hole = foundHoles(h);
                xLeft = hole.col_min - patch.col_min;
                xRight = patch.col_max - hole.col_max;
                yBottom = patch.row_max - hole.row_max;
                yTop = hole.row_min - patch.row_min;
                ii = patch.row_min-box.row_min+1;
                for i=patch.row_min:patch.row_max
                    jj = patch.col_min-box.col_min+1;
                    for j=patch.col_min:patch.col_max
                        if(sum(t.cropped_data(ii,jj,:),3)==0)
                            continue
                        end
                        if(sum(obj.outimg(i,j,:),3)~=0)
                            alphaX = -1;
                            alphaY = -1;
                            if xLeft>0 && j <= hole.col_min
                                xDist = hole.col_min - j;
                                alphaX = 1 - (xDist/xLeft);
                                xMax = xLeft;
                            elseif xRight>0 && j >= hole.col_max
                                xDist = j - hole.col_max;
                                alphaX = 1 - (xDist/xRight);
                                xMax = xRight;
                            end
                            if yTop>0 && i <= hole.row_min
                                yDist = hole.row_min - i;
                                alphaY = 1 - (yDist/yTop);
                                yMax = yTop;
                            elseif yBottom>0 && i >= hole.row_max
                                yDist = i - hole.row_max;
                                alphaY = 1 - (yDist/yBottom);
                                yMax = yBottom;
                            end
                            if (alphaX == -1 && alphaY == -1)
                                %a previous hole from this same image
                                %already filled this pixel, no problem
                            else
                                if (alphaX == -1)
                                    alpha = alphaY;
                                elseif (alphaY == -1)
                                    alpha = alphaX;
                                else
                                    diagMax = min([xMax,yMax]);
                                    diagDist = min([diagMax,sqrt(xDist^2 + yDist^2)]);
                                    alpha = 1 - diagDist/diagMax;
                                end
                                obj.outimg(i,j,:) = ...
                                    t.cropped_data(ii,jj,:)*alpha+...
                                    obj.outimg(i,j,:)*(1-alpha);
                            end
                        else
                            obj.outimg(i,j,:) = t.cropped_data(ii,jj,:);
                        end
                        jj = jj+1;
                    end
                    ii = ii+1;
                end
            end
        end
        
        
        function obj = set_sift(obj)
            for idx = 1:size(obj.images,2)
                fprintf('Getting SIFT descriptors for img: %d\n', idx);
                obj.images(idx) = obj.images(idx).set_sift();
            end
        end
        
        function obj = setup_DAG(obj)
            start_node = plane_img();
            end_node = plane_img();
            if obj.sortVertical
                start_node.mytile_on_plane.cropped_box.col_min = 1;
                start_node.mytile_on_plane.cropped_box.col_max = obj.width;
                start_node.mytile_on_plane.cropped_box.row_min = 1;
                start_node.mytile_on_plane.cropped_box.row_max = 2;
                end_node.mytile_on_plane.cropped_box.col_min = 1;
                end_node.mytile_on_plane.cropped_box.col_max = obj.width;
                end_node.mytile_on_plane.cropped_box.row_min = obj.height-1;
                end_node.mytile_on_plane.cropped_box.row_max = obj.height;
                start_node.mytile_on_plane.orig_box = ...
                    start_node.mytile_on_plane.cropped_box;
                end_node.mytile_on_plane.orig_box = ...
                    end_node.mytile_on_plane.cropped_box;
                start_node.mytile_on_plane.cropped_data = zeros(2,obj.width,3);
                end_node.mytile_on_plane.cropped_data = zeros(2,obj.width,3);
                start_node.mytile_on_plane.orig_data = zeros(2,obj.width,3);
                end_node.mytile_on_plane.orig_data = zeros(2,obj.width,3);
            else
                start_node.mytile_on_plane.cropped_box.col_min = 1;
                start_node.mytile_on_plane.cropped_box.col_max = 2;
                start_node.mytile_on_plane.cropped_box.row_min = 1;
                start_node.mytile_on_plane.cropped_box.row_max = obj.height;
                end_node.mytile_on_plane.cropped_box.col_min = obj.width - 1;
                end_node.mytile_on_plane.cropped_box.col_max = obj.width;
                end_node.mytile_on_plane.cropped_box.row_min = 1;
                end_node.mytile_on_plane.cropped_box.row_max = obj.height;
                start_node.mytile_on_plane.orig_box = ...
                    start_node.mytile_on_plane.cropped_box;
                end_node.mytile_on_plane.orig_box = ...
                    end_node.mytile_on_plane.cropped_box;
                start_node.mytile_on_plane.cropped_data = zeros(obj.height,2,3);
                end_node.mytile_on_plane.cropped_data = zeros(obj.height,2,3);
                start_node.mytile_on_plane.orig_data = zeros(obj.height,2,3);
                end_node.mytile_on_plane.orig_data = zeros(obj.height,2,3);
            end
            start_node.cam_dist = 0;
            end_node.cam_dist = 0;
            start_node.cam_angle = 0;
            end_node.cam_angle = 0;
            obj.images = [start_node obj.images end_node];
        end
        
        function obj = set_overlap(obj, maxoverlap)
            for idx1 = 1:size(obj.images,2)
                obj.images(idx1).overlap = [];
                limit = min(size(obj.images,2), idx1+maxoverlap);
                for idx2 = idx1+1:limit
                    %minimum band area for first and last node
                    blend = obj.blendpx;
                    if idx1 == 1 || idx2 == size(obj.images,2);
                        blend = 1;
                    end
                    b1 = obj.images(idx1).mytile_on_plane.cropped_box;
                    b2 = obj.images(idx2).mytile_on_plane.cropped_box;
                    if(box_overlap(b1, b2, blend))
                        obj.images(idx1).overlap = [obj.images(idx1).overlap ...
                            idx2];
                    end
                end
            end
        end
        
        function obj = fix_locations(obj)
            obj = obj.set_overlap(3);
            
            % Fix the positions with least squares
            xmat = zeros(1,size(obj.images,2));
            ymat = zeros(1,size(obj.images,2));
            xobs = 0; yobs = 0; w = 0;
            for idx1 = 1:size(obj.images,2)
                if(~obj.images(idx1).useful)
                    continue;
                end
                s1 = obj.images(idx1);
                for idx2_i = 1:size(s1.overlap,2)
                    idx2 = s1.overlap(idx2_i);
                    if(~obj.images(idx2).useful)
                        continue;
                    end
                    s2 = obj.images(idx2);
                    fprintf('Matching images: %d and %d\n', idx1, idx2)
                    % Shift is the distance from one image to the next
                    [row_shift col_shift] = get_match_and_shift(s1.mytile_on_plane, s2.mytile_on_plane);
                    matches = true;
                    if(row_shift == 0 && col_shift == 0)
                        matches = false;
                    end
                    old_row_shift = s2.mytile_on_plane.cropped_box.row_min - s1.mytile_on_plane.cropped_box.row_min;
                    old_col_shift = s2.mytile_on_plane.cropped_box.col_min - s1.mytile_on_plane.cropped_box.col_min;
                    diff = abs(row_shift-old_row_shift) + abs(col_shift-old_col_shift);
                    if(diff < obj.maxshift && matches)
                        fprintf('row_shift: %f\told_row_shift: %f\n', row_shift, old_row_shift);
                        fprintf('col_shift: %f\told_col_shift: %f\n', col_shift, old_col_shift);
                        xmat(end,idx1) = -1; xmat(end,idx2) = 1;
                        ymat(end,idx1) = -1; ymat(end,idx2) = 1;
                        xmat(end+1,:) = 0; ymat(end+1,:) = 0;
                        xobs(end) = col_shift; xobs(end+1) = 0;
                        yobs(end) = row_shift; yobs(end+1) = 0;
                        w(end) = 1; w(end+1) = 0;
                    end
                    xmat(end,idx1) = -1; xmat(end,idx2) = 1;
                    ymat(end,idx1) = -1; ymat(end,idx2) = 1;
                    xmat(end+1,:) = 0; ymat(end+1,:) = 0;
                    xobs(end) = old_col_shift; xobs(end+1) = 0;
                    yobs(end) = old_row_shift; yobs(end+1) = 0;
                    w(end) = 0.01; w(end+1) = 0;
                end
                xmat(end,idx1) = 1;
                ymat(end,idx1) = 1;
                xmat(end+1,:) = 0; ymat(end+1,:) = 0;
                xobs(end) = s1.mytile_on_plane.cropped_box.col_min;  xobs(end+1) = 0;
                yobs(end) = s1.mytile_on_plane.cropped_box.row_min;  yobs(end+1) = 0;
                w(end) = 0.01; w(end+1) = 0;
            end
            
            xmat(end,1) = 1; ymat(end,1) = 1;
            xobs(end) = obj.images(1).mytile_on_plane.cropped_box.col_min;
            yobs(end) = obj.images(1).mytile_on_plane.cropped_box.row_min;
            w(end) = 0;
            
            % Solve using weighted least squares
            new_col_mins = lscov(xmat,xobs',w');
            new_row_mins = lscov(ymat,yobs',w');
            
            for idx = 1:size(obj.images,2)
                diff_col = round(new_col_mins(idx) - obj.images(idx).mytile_on_plane.cropped_box.col_min);
                diff_row = round(new_row_mins(idx) - obj.images(idx).mytile_on_plane.cropped_box.row_min);
                %obj.images(idx).mytile.cropped_box.col_min = obj.images(idx).mytile.cropped_box.col_min + diff_col;
                %obj.images(idx).mytile.cropped_box.col_max = obj.images(idx).mytile.cropped_box.col_max + diff_col;
                %obj.images(idx).mytile.cropped_box.row_min = obj.images(idx).mytile.cropped_box.row_min + diff_row;
                %obj.images(idx).mytile.cropped_box.row_max = obj.images(idx).mytile.cropped_box.row_max + diff_row;
                
                obj.images(idx).mytile.orig_box.col_min = obj.images(idx).mytile.orig_box.col_min + diff_col;
                obj.images(idx).mytile.orig_box.col_max = obj.images(idx).mytile.orig_box.col_max + diff_col;
                obj.images(idx).mytile.orig_box.row_min = obj.images(idx).mytile.orig_box.row_min + diff_row;
                obj.images(idx).mytile.orig_box.row_max = obj.images(idx).mytile.orig_box.row_max + diff_row;
            end
            obj = obj.set_tiles_on_plane();
        end
    end
    
end

