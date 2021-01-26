import sys
from random import shuffle

import numpy as np


def main():
    # Get the arguments
    training_x = sys.argv[1]
    training_y = sys.argv[2]
    test_x = sys.argv[3]

    # Get a list of the dataset:
    training_x = parse_features(training_x)
    training_y = parse_classifications(training_y)
    training_dataset = combine_x_y(training_x, training_y)
    test_x = parse_features(test_x)

    # Run the Perceptron algorithm:
    accuracy = perceptron(training_dataset, test_x)
    print(accuracy)


def perceptron(training_dataset, test_x):
    # Parameters
    eta = 0.1
    epochs = 20

    # Since all weights are floats, a numpy array is possible to create:
    weights = np.zeros((3, len(training_dataset[0]) - 1))

    # Train:
    for e in range(epochs):
        # shuffle(training_dataset)
        for idx, x in enumerate(training_dataset):
            y = x[-1]
            x_features = training_vector_to_numpy(x)

            # Predict
            y_hat = np.argmax(np.dot(weights, x_features))

            # Update
            if y != y_hat:
                weights[y, :] = weights[y, :] + eta*x_features
                weights[y_hat, :] = weights[y_hat, :] - eta*x_features
        eta = eta / 32

    # Test (classify the test set):
    final_pred = []
    for test in test_x:
        # Convert to numpy array (although not necessary?):
        test_features = np.asarray(test, dtype=np.float64)
        y_hat = np.argmax(np.dot(weights, test_features))
        # result_0 = np.dot(weights[0], test_features)
        # result_1 = np.dot(weights[1], test_features)
        # result_2 = np.dot(weights[2], test_features)
        final_pred.append(y_hat)

    success = 0
    for prediction, real in zip(final_pred, training_dataset[:29]):
        classification = real[-1]
        if prediction == classification:
            success += 1
    accuracy = success/30
    return accuracy


def training_vector_to_numpy(training_vector):
    # Make a copy of the training vector without the last element (classification):
    features_only = training_vector[:-1]

    # Convert the features-only vector to a numpy array of floats:
    return np.asarray(features_only, dtype=np.float64)


def parse_features(path_to_file):
    features_vector = []
    with open(path_to_file) as file:
        for line in file:
            line_features = line.strip().split(",")
            line_features = encode_categorical(line_features)
            line_features = [float(feature) for feature in line_features]
            features_vector.append(line_features)
    file.close()
    return features_vector


def parse_classifications(path_to_file):
    classif_vector = []
    with open(path_to_file) as file:
        for line in file:
            classif_vector.append(int(line))
    file.close()
    return classif_vector


def combine_x_y(training_x, training_y):
    training_data = []
    for idx in range(len(training_x)):
        training_x[idx].append(training_y[idx])
        training_data.append(training_x[idx])
    return training_data


def encode_categorical(features_vector):
    s = str(features_vector[0])
    if s == "I":
        features_vector[0] = 0
    if s == "M":
        features_vector[0] = -1
    if s == "F":
        features_vector[0] = 1
    return features_vector


if __name__ == "__main__":
    main()
