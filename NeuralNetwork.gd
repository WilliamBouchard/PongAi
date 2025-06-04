class_name NeuralNetwork

var weights = [] 
var biases = []  
var layer_sizes = []
var learning_rate = 0.01  
var max_gradient_value = 2

func _init(_layer_sizes: Array, _learning_rate: float = 0.01):
	layer_sizes = _layer_sizes
	learning_rate = _learning_rate
	
	for i in range(layer_sizes.size() - 1):
		var input_size = layer_sizes[i]
		var output_size = layer_sizes[i + 1]
		weights.append(random_matrix(input_size, output_size))
		biases.append(random_vector(output_size))
		
# Forward propagation
func forward(input: Array) -> Dictionary:
	var activations = input
	var zs = []  # Pre-activation values
	var activations_list = [activations]  # Store activations for backprop
	
	for i in range(weights.size()):
		var z = matmul(activations, weights[i])
		
		for j in range (z.size()):
			z[j] = z[j]+biases[i][j]
		
		zs.append(z)
		if i < weights.size() - 1:
			activations = relu(z)
		else:
			activations = z  # Output layer (no activation)
			
		activations_list.append(activations)
	
	return {"activations": activations_list, "zs": zs, "output": activations_list[-1]}

func backpropagate(input: Array, target: Array):
# Forward pass
	var result = forward(input)
	var activations_list = result["activations"]
	var zs = result["zs"]

# Calculate the error for the output layer
	var delta = []
	var output_activations = result["output"]
	for i in range(target.size()):
		delta.append(output_activations[i] - target[i])

	# Gradients for weights and biases
	var weight_grads = []
	var bias_grads = []

	# Backpropagate through layers
	for l in range(weights.size() - 1, -1, -1):
		if l < weights.size() - 1:
			# Apply ReLU derivative
			var relu_derivative = zs[l].map(func(val): return 1 if val > 0 else 0)
			for i in range(delta.size()):
				delta[i] *= relu_derivative[i]

		# Calculate gradients
		var activation_transposed = transpose_vector(activations_list[l])
		
		var weight_grad = []
		for i in range(delta.size()):  
			var row = []
			for j in range(activations_list[l].size()):  
				row.append(delta[i] * activations_list[l][j])  
			weight_grad.append(row)
		weight_grads.append(transpose_matrix(weight_grad))
		
		bias_grads.append(delta)

		# Update delta for next layer
		if l > 0:
			delta = matmul(delta, transpose_matrix(weights[l]))
	
	weight_grads.reverse()
	bias_grads.reverse()
	
	# Update weights and biases
	for l in range(weights.size()):
		for i in range(weights[l].size()):
			for j in range(weights[l][i].size()):
				weights[l][i][j] -= learning_rate * clamp(weight_grads[l][i][j], -max_gradient_value, max_gradient_value)
		
		for i in range(biases[l].size()):
			biases[l][i] -= learning_rate * clamp(bias_grads[l][i], -max_gradient_value, max_gradient_value)

func matmul(activations: Array, weights: Array) -> Array:
	var result = []
	for i in range(weights[0].size()):  
		var sum = 0
		for j in range(activations.size()):  
			sum += activations[j] * weights[j][i]
		result.append(sum)
	return result

func outer_product(column_vector: Array, row_vector: Array) -> Array:
	var result = []
	for i in range(column_vector.size()):  # Iterate over rows in the column vector
		var row = []
		for j in range(row_vector.size()):  # Iterate over elements in the row vector
			row.append(column_vector[i][0] * row_vector[j])  # Multiply elements
		result.append(row)  # Add the row to the result matrix
	return result


func relu(x: Array) -> Array:
	return x.map(func(val): return max(val, 0))
	
#Initialization helper functions
	
func random_matrix(rows: int, cols: int) -> Array:
	var matrix = []
	for i in range(rows):
		var row = []
		for j in range(cols):
			row.append(randf_range(-1, 1))  
		matrix.append(row)
	return matrix

func random_vector(size: int) -> Array:
	var vector = []
	for i in range(size):
		vector.append(randf_range(-1, 1))
	return vector

#Utils

func transpose_vector(vector: Array) -> Array:
	# Convert a 1D vector into a column vector
	var transposed = []
	for i in range(vector.size()):
		transposed.append([vector[i]])  # Each element becomes its own row
	return transposed

func transpose_matrix(matrix: Array) -> Array:
	if matrix.size() == 0:
		return []
	
	var transposed = []
	for col in range(matrix[0].size()):
		var new_row = []
		for row in range(matrix.size()):
			new_row.append(matrix[row][col])  # Collect elements column-wise
		transposed.append(new_row)
	return transposed
