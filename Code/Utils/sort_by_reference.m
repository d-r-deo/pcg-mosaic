%% Helper function to sort by label order
function resortedInds = sort_by_reference(current_labels, reference_order)
    % Helper: Resort indices based on reference order
    resortedInds = [];
    for i = 1:numel(reference_order)
        idx = find(strcmp(current_labels, reference_order{i}) == 1);
        if ~isempty(idx)
            resortedInds = [resortedInds idx];
        end
    end
end