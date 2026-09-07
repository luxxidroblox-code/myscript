-- Run ini di executor, liat output
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") then
        print(obj.Name, "|", obj.Parent.Name, "|", obj.Parent.ClassName)
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("TextLabel") then
                print("  TextLabel:", child.Text, "| Color:", child.TextColor3)
            end
            if child:IsA("ImageLabel") then
                print("  ImageLabel:", child.Image)
            end
        end
    end
end