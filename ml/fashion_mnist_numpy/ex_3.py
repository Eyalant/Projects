import sys
import numpy as np
import matplotlib.pyplot as plt
from random import shuffle
from random import Random


def main():
    # Get inputs:
    path_training_x, path_training_y, path_test_x, path_test_y_correct = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    training_x_np_array = np.loadtxt(path_training_x)
    training_y_np_array = np.loadtxt(path_training_y)
    training_combined_list = combine_x_y(training_x_np_array, training_y_np_array, size_of_set=training_x_np_array.shape[0])
    test_x_np_array = np.loadtxt(path_test_x)
    test_y_np_array = np.loadtxt(path_test_y_correct)

    # For testing:
    test_combined_list = combine_x_y(test_x_np_array, test_y_np_array, size_of_set=test_x_np_array.shape[0])
    weights_and_biases = create_weights_and_biases(h1_size=128)

    # Train the network. Iterate over the inputs and feed them forward:
    epochs = 50
    for e in range(epochs):
        print(e)
        shuffle(training_combined_list)

        # Loop over the training set:
        for i in training_combined_list:
            example_i_vector = i['vector']
            #plt.imshow(example_i_vector.reshape(28, -1), cmap='gray')
            #plt.show()
            example_i_vector = example_i_vector / np.float64(255)
            example_i_label = i['label']
            result_forward_prop = forward_prop(example_i_vector, example_i_label, weights_and_biases, general_loss=0)
            result_backwards_prop = backwards_prop(result_forward_prop)
            update_weights_and_biases(weights_and_biases, result_backwards_prop, 0.0001)
        classify(test_combined_list, weights_and_biases)


def classify(test_combined_list, weights_and_biases):
    predictions = []
    success = 0
    general_loss = 0
    for example_i in test_combined_list:
        example_i_vector = example_i['vector'] / np.float64(255)
        result_forward_prop = forward_prop(example_i_vector, example_i['label'], weights_and_biases, general_loss)
        general_loss = result_forward_prop['loss']
        pred = np.argmax(result_forward_prop['h2'])
        predictions.append(pred)
        if pred == example_i['label']:
            success += 1

    print("accuracy:" + str(success / len(test_combined_list) * 100))
    print("loss:" + str(general_loss))

    #with open('test_y', 'w') as file:
    #    for pred in predictions:
    #        file.write(str(int(pred)) + '\n')


def update_weights_and_biases(weights_and_biases, results_backwards_prop, eta):
    dw1, db1, dw2, db2 = [results_backwards_prop[key] for key in ('dw1', 'db1', 'dw2', 'db2')]
    weights_and_biases['W1'] -= eta * dw1
    weights_and_biases['b1'] = weights_and_biases['b1'] - (eta * db1).flatten()
    weights_and_biases['W2'] -= eta * dw2
    weights_and_biases['b2'] = weights_and_biases['b2'] - (eta * db2).flatten()


def forward_prop(example_i_vector, example_i_label, weights_and_biases, general_loss):
    W1, b1, W2, b2 = [weights_and_biases[key] for key in ('W1', 'b1', 'W2', 'b2')]
    z1 = np.dot(W1, example_i_vector) + b1
    h1 = relu(z1)
    z2 = np.dot(W2, h1) + b2
    h2 = softmax(z2)
    loss = -np.log(h2[int(example_i_label)])
    general_loss += loss
    y_onehot_label = make_onehot_label_vector(example_i_label)
    ret = {'example_i_vector': example_i_vector,
           'z1': z1, 'h1': h1, 'z2': z2, 'h2': h2, 'y': y_onehot_label, 'loss': general_loss}
    for key in weights_and_biases:
        ret[key] = weights_and_biases[key]
    return ret


def backwards_prop(result_forward_prop):
    example_i_vector, z1, h1, z2, h2, y = [result_forward_prop[key] for key in ('example_i_vector',
                                                                                'z1', 'h1', 'z2', 'h2', 'y')]
    dz2 = h2 - y
    dz2 = dz2.T
    dW2 = np.dot(dz2, h1[np.newaxis])
    db2 = dz2
    dz1 = np.dot(result_forward_prop['W2'].T, (h2 - y).T) * (relu_derivative(z1)[np.newaxis]).T
    dW1 = np.dot(dz1, example_i_vector[np.newaxis])
    db1 = dz1
    return {'db1': db1, 'dw1': dW1, 'db2': db2, 'dw2': dW2}


def make_onehot_label_vector(example_i_float_label):
    onehot_label_vector = np.eye(10)[np.array(int(example_i_float_label)).reshape(-1)]
    return onehot_label_vector


def combine_x_y(training_x_np_array, training_y_np_array, size_of_set):
    training_combined = []
    for idx in range(size_of_set):
        combined_dict = {'vector': training_x_np_array[idx], 'label': training_y_np_array[idx]}
        training_combined.append(combined_dict)
    return training_combined


def relu_derivative(z):
    z[z > 0] = 1
    z[z <= 0] = 0
    return z


def relu(z):
    return np.maximum(z, 0)


def softmax(z):
    e_of_z = np.exp(z - np.max(z))
    if e_of_z.sum() == 0:
        return 0
    return e_of_z / e_of_z.sum()


def create_weights_and_biases(h1_size):
    # FOR DEBUG:
    #np.random.seed(0)
    W1 = np.random.uniform(-0.08, 0.08, (h1_size, 784))
    # FOR DEBUG:
    #np.random.seed(1)
    b1 = np.random.uniform(-0.08, 0.08, h1_size)
    np.random.seed(2)
    W2 = np.random.uniform(-0.08, 0.08, (10, h1_size))
    #np.random.seed(3)
    b2 = np.random.uniform(-0.08, 0.08, 10)
    params = {'W1': W1, 'b1': b1, 'W2': W2, 'b2': b2}
    return params


if __name__ == "__main__":
    main()