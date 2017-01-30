--[[
    Dota2 Utility for DL
]]

local D2NN = {}

local Matrix = {
    -- Zero based index
    data = {},
    shape = {}
}

D2NN.Matrix = Matrix

function Matrix:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.data = {}
    o.shape = {}
    return o
end

function Matrix:SetDataShape(data, rows, cols)
    self.data = data
    self:SetShape(rows,cols)
end

function Matrix:SetShape(rows,cols)
    self.shape = {rows,cols}
end

function Matrix.__mul(m1,m2)
    if m1.shape[2] ~= m2.shape[1] then
        local msg = string.format("__mul: matrix dim mismatch:\nm1:(%d,%d) m2:(%d,%d)",
        m1.shape[1],m1.shape[2],m2.shape[1],m2.shape[2])
        print(msg)
        error(msg)
    end
    local dim1 = m1.shape[1]
    local dim2 = m2.shape[2]
    local dim3 = m1.shape[2]
    local ret = Matrix:new()
    ret:SetShape(dim1,dim2)
    for i = 0, m1.shape[1] - 1, 1 do
        for j = 0, m2.shape[2] - 1, 1 do
            local s = 0
            for c = 0, m1.shape[2] - 1, 1 do
                s = s + m1.data[i * dim3 + c] * m2.data[c * dim2 + j]
            end
            ret.data[i * dim2 + j] = s
        end 
    end
    return ret
end

function Matrix.__add(m1,m2)
    if m1.shape[1] ~= m2.shape[1] or
        m1.shape[2] ~= m2.shape[2] then
        local msg = string.format("__add: matrix dim mismatch:\nm1:(%d,%d) m2:(%d,%d)",
        m1.shape[1],m1.shape[2],m2.shape[1],m2.shape[2])
        print(msg)
        error(msg)
    end
    local ret = Matrix:new()
    ret:SetShape(m2.shape[1],m2.shape[2])
    local tmpdim = m1.shape[1] * m1.shape[2] - 1
    for i = 0, tmpdim, 1 do
        ret.data[i] = m1.data[i] + m2.data[i]
    end
    return ret
end

function Matrix:Activate(fn)
    if type(fn) ~= "function" then
        error("type of fn must be function, not",type(fn))
    end

    local tmpdim = self.shape[1] * self.shape[2] - 1
    for i = 0, tmpdim, 1 do
        self.data[i] = fn(self.data[i])
    end
end

local Layer = {
}

D2NN.Layer = Layer

D2NN.Activations = {}

function D2NN.Activations.relu(x)
    if x < 0 then
        return 0
    else
        return x
    end
end

D2NN.Activations.tanh = math.tanh

function D2NN.Activations.sigmoid(x)
    return 1 / (1 + math.exp( -x ))
end



function Layer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Layer:FowardProp(input)
    error("pure virtual function must not be called")
end



local FCLayer = Layer:new()

D2NN.FCLayer = FCLayer

function FCLayer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function FCLayer:SetW(W)
    self.W = W
end

function FCLayer:SetB(B)
    self.B = B
end

function FCLayer:SetActivation(fn)
    self.activation = fn
end

function FCLayer:ForwardProp(input)
    local ret = input * self.W
    ret = ret + self.B
    if self.activation then
        ret:Activate(self.activation)
    end
    return ret
end

return D2NN