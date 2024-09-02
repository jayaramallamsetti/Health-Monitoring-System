import g4p_controls.*;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.ResultSet;
import processing.net.*;
import controlP5.*;
import processing.serial.*;
import java.util.Arrays;
import java.io.DataOutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
boolean savingThreadActive = false;

String botToken = "6887716997:AAGXlPq0B3298Y54deznedwEkryPgVS0qbk";
  // Assuming this is the username
  

  // Construct the Telegram Bot API URL
  String apiUrl = "https://api.telegram.org/bot" + botToken + "/sendMessage";

  // Construct the POST data
  
String receivedMessage = "";
processing.net.Client client; 
Serial port;
Chart myChart1;
Chart myChart2;
Chart myChart3;
ControlP5 cp5;
PFont font;
int nl = 10;
String received = null;
String[] readings;
int stop_flag = 0;
int start_flag = 0;
PrintWriter save_data;
int requestInterval = 300; // Set the interval for requesting values (in milliseconds)
int lastRequestTime = 0;
String esp32IP = "192.168.137.111";
int esp32Port = 80;

GTextField usernameField, passwordField, emailField, signInUsernameField, signInPasswordField;
GButton signupButton, AlreadyRegisteredButton, newuserButton, signInButton;
GLabel messageLabel, signInMessageLabel;
GLabel signupLabel, signInLabel;
String name="";
GLabel usernameLabel,passwordLabel,emailLabel,signInUsernameLabel,signInPasswordLabel;
int id;

Connection conn = null;
boolean signedUp = false;
boolean signin = false;

void setup() {
  size(800, 450); 
  createGUI();
  connectToDatabase();
}

void draw() {
  background(220);
  if(signin){
      background(0, 0, 0);
  fill(0, 255, 0);
  textFont(font);
  text("PULSE WAVEFORM", 60, 80);

  // Check if it's time to send a new request
  int currentTime = millis();

  if (currentTime - lastRequestTime >= requestInterval) {
    // Send a request
    sendRequest();
    // Update the last request time
    lastRequestTime = currentTime;
  }

  // Handle the response if available
  if (client != null && client.active() && client.available() > 0) {
    receivedMessage = client.readString();
    received = receivedMessage;
    if (received != null && start_flag == 1 && stop_flag == 0) {
      readings = received.split(",", 4);
      readings[1] = nf(float(readings[1]) + f(), 0, 2);
      readings[2] = nf(float(readings[2]) + f(), 0, 2);
       readings[3] = nf(float(readings[3]) + f(), 0, 2);
       println(readings[1], readings[2], readings[3]);

      String dataToAppend = hour() + "." + nf(minute(), 2) + "." + nf(second(), 2) + "." + nf(millis(), 3) + " : " +
        readings[1] + "," + readings[2] + "," + readings[3];

      String[] existingData = loadStrings("sensor_data.txt");
      String[] newData = concat(existingData, new String[] { dataToAppend });
      saveStrings("sensor_data.txt", newData);

      save_data.println(hour() + "." + "0" + minute() + "." + second() + "." + millis() + " : " +
        readings[1] + "," + readings[2] + "," + readings[3]);

      myChart1.push("incoming", float(readings[1]));
      myChart2.push("incoming", float(readings[2]));
      myChart3.push("incoming", float(readings[3]));
      if (name!=""){
        int numid=getUserIdFromDatabase(name);
        insertSensorData(numid,readings[1],readings[2],readings[3]) ;

      }
       
    }
    // Uncomment the next line if you want to close the connection after receiving a response
    client.stop();
  }
  }
  
}
void insertSensorData(int id, String value1, String value2, String value3) {
  try {
    // Prepare the INSERT SQL statement
    String insertQuery = "INSERT INTO PULSE (id, VATA, PIIA, KAPHA, DA_TE) VALUES (?, ?, ?, ?, NOW())";
    PreparedStatement pstmt = conn.prepareStatement(insertQuery);
    pstmt.setInt(1, id);
    pstmt.setFloat(2, float(value1));
    pstmt.setFloat(3, float(value2));
    pstmt.setFloat(4, float(value3));

    // Execute the INSERT query
    pstmt.executeUpdate();

    // Close resources
    pstmt.close();
  } catch (SQLException e) {
    e.printStackTrace();
    println("Error inserting sensor data into the database");
  }
}

void pulsesetup(){
  printArray(Serial.list());
  cp5 = new ControlP5(this);
  font = createFont("calibri light bold", 20);

  cp5.addButton("Start")
    .setPosition(80, 120)
    .setSize(120, 70)
    .setFont(font);

  cp5.addButton("Stop")
    .setPosition(80, 220)
    .setSize(120, 70)
    .setFont(font);

  cp5.addButton("Save")
    .setPosition(80, 320)
    .setSize(120, 70)
    .setFont(font);

  myChart1 = cp5.addChart("pulse waveform 1")
    .setPosition(260, 10)
    .setSize(500, 125)
    .setView(Chart.LINE)
    .setRange(0, 150);
    

  myChart1.addDataSet("incoming");
  myChart1.setData("incoming", new float[100]);

  myChart2 = cp5.addChart("pulse waveform 2")
    .setPosition(260, 155)
    .setSize(500, 125)
    .setView(Chart.LINE)
    .setRange(0, 150);

  myChart2.addDataSet("incoming");
  myChart2.setData("incoming", new float[100]);

  myChart3 = cp5.addChart("pulse waveform 3")
    .setPosition(260, 300)
    .setSize(500, 125)
    .setView(Chart.LINE)
    .setRange(0, 150);

  myChart3.addDataSet("incoming");
  myChart3.setData("incoming", new float[100]);

  save_data = createWriter("sensordata.txt" + day() + "-" + month() + "-" + year() + ":" + hour() + "." + minute());
}
void createGUI() {
  signupLabel = new GLabel(this, 200, 10, 100, 20);
  signupLabel.setText("Sign Up");

  usernameLabel = new GLabel(this, 50, 30, 100, 30);
  usernameLabel.setText("Username:");

  passwordLabel = new GLabel(this, 50, 80, 100, 30);
  passwordLabel.setText("Password:");

  emailLabel = new GLabel(this, 50, 130, 100, 30);
  emailLabel.setText("TelegramChatID");

  usernameField = new GTextField(this, 150, 30, 200, 30);
  passwordField = new GTextField(this, 150, 80, 200, 30);
  emailField = new GTextField(this, 150, 130, 200, 30);

  signupButton = new GButton(this, 50, 180, 100, 30);
  signupButton.setText("Sign Up");

  AlreadyRegisteredButton = new GButton(this, 200, 180, 100, 30);
  AlreadyRegisteredButton.setText(" Registered?");

  messageLabel = new GLabel(this, 100, 220, 200, 30);
  messageLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
}

void connectToDatabase() {
  String dbURL = "jdbc:mysql://localhost:3306/SIGNUP";
  String dbUser = "root";
  String dbPassword = "Guru@2002";

  try {
    conn = DriverManager.getConnection(dbURL, dbUser, dbPassword);
  } catch (SQLException e) {
    e.printStackTrace();
    println("Database connection error");
  }
}

void handleButtonEvents(GButton button, GEvent event) {
  if (button == signupButton && event == GEvent.CLICKED) {
    String username = usernameField.getText();
    String password = passwordField.getText();
    String email = emailField.getText();

    if (signupSuccessful(username, password, email)) {
      if (insertUser(username, password, email)) {
        String welcomeMessage = "Welcome, " + username + "!" + " Kindly press registered and signin using user id " ;
        messageLabel.setText(welcomeMessage);
      } else {
        messageLabel.setText("Signup failed. Please try again.");
      }
    } else {
      messageLabel.setText("Invalid input. Please check your information.");
    }
  }

  if (button == AlreadyRegisteredButton && event == GEvent.CLICKED) {
    // Clear the existing GUI
    clearGUI();

    // Create the sign-in GUI
    createSignInGUI();
  }

  if (button == newuserButton && event == GEvent.CLICKED) {
    // Clear the existing GUI
    clearSignInGUI();

    // Create the sign-up GUI
    createGUI();
  }
  if (button == signInButton && event == GEvent.CLICKED) {
    String enteredUsername = signInUsernameField.getText();
    String enteredPassword = signInPasswordField.getText();

    if (checkUserCredentials(enteredUsername, enteredPassword)) {
      clearSignInGUI();
      pulsesetup();
      signin = true;
      id =  getUserIdFromDatabase(enteredUsername);
    } else {
      signInMessageLabel.setText("Invalid username or password. Please try again.");
    }
  }
}
int getUserIdFromDatabase(String username) {
  int userId = -1; // Default value if no user is found

  try {
    // Prepare the SELECT SQL statement
    String selectQuery = "SELECT id FROM SIGN WHERE username = ?";
    PreparedStatement pstmt = conn.prepareStatement(selectQuery);
    pstmt.setString(1, username);

    // Execute the SELECT query
    ResultSet resultSet = pstmt.executeQuery();

    // Check if any row is returned
    if (resultSet.next()) {
      // Get the id from the result set
      userId = resultSet.getInt("id");
    }

    // Close resources
    resultSet.close();
    pstmt.close();
  } catch (SQLException e) {
    e.printStackTrace();
    println("Error retrieving user id from the database");
  }

  return userId;
}

void clearGUI() {
  usernameField.setVisible(false);
  emailLabel.setVisible(false);
  usernameLabel.setVisible(false);
  passwordLabel.setVisible(false);
  
  passwordField.setVisible(false);
  emailField.setVisible(false);
  signupButton.setVisible(false);
  AlreadyRegisteredButton.setVisible(false);
  messageLabel.setVisible(false);
  signupLabel.setVisible(false);
}

void createSignInGUI() {
  signInLabel = new GLabel(this, 200, 10, 100, 20);
  signInLabel.setText("Sign In");

  signInUsernameLabel = new GLabel(this, 50, 30, 100, 30);
  signInUsernameLabel.setText("Username:");

  signInPasswordLabel = new GLabel(this, 50, 80, 100, 30);
  signInPasswordLabel.setText("Password:");

  signInUsernameField = new GTextField(this, 150, 30, 200, 30);
  signInPasswordField = new GTextField(this, 150, 80, 200, 30);

  signInButton = new GButton(this, 50, 130, 100, 30);
  signInButton.setText("Sign In");

  newuserButton = new GButton(this, 180, 130, 100, 30);
  newuserButton.setText("New User?");

  signInMessageLabel = new GLabel(this, 100, 220, 200, 30);
  signInMessageLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
}

void clearSignInGUI() {
  signInUsernameField.setVisible(false);
  signInPasswordField.setVisible(false);
  signInButton.setVisible(false);
  signInUsernameLabel.setVisible(false);
  signInPasswordLabel.setVisible(false);
  newuserButton.setVisible(false);
  signInMessageLabel.setVisible(false);
  signInLabel.setVisible(false);
}

boolean signupSuccessful(String username, String password, String email) {
  return !username.isEmpty() && !password.isEmpty() && !email.isEmpty();
}
float f() {
  float randomNumber = random(8);
  String formattedNumber = nf(randomNumber, 0, 2);
  float result = float(formattedNumber);
  return result;
}


boolean insertUser(String username, String password, String email) {
  try {
    String insertQuery = "INSERT INTO SIGN (username, password1, email) VALUES (?, ?, ?)";
    PreparedStatement pstmt = conn.prepareStatement(insertQuery);
    pstmt.setString(1, username);
    pstmt.setString(2, password);
    pstmt.setString(3, email);
    pstmt.executeUpdate();
    pstmt.close();
    return true;
  } catch (SQLException e) {
    e.printStackTrace();
    println("user account is already there try to sign in ");
    return false;
  }
}
boolean checkUserCredentials(String enteredUsername, String enteredPassword) {
  try {
    // Query the database to check if the entered credentials exist
    name= enteredUsername;
    String query = "SELECT * FROM SIGN WHERE username = ? AND password1 = ?";
    PreparedStatement pstmt = conn.prepareStatement(query);
    pstmt.setString(1, enteredUsername);
    pstmt.setString(2, enteredPassword);
    
    // Execute the query
    ResultSet resultSet = pstmt.executeQuery();

    // Check if any row is returned, indicating a matching user
    if (resultSet.next()) {
      return true; // User with the provided credentials exists
    } else {
      return false; // No user found with the provided credentials
    }
  } catch (SQLException e) {
    e.printStackTrace();
    return false; // Error occurred during database query
  }
}

void Start() {
  start_flag = 1;
  stop_flag = 0;
}

void Stop() {
  stop_flag = 1;
  start_flag = 0;
   
}
void Save() {
  if (!savingThreadActive) {
    // Start a new thread for saving data
    thread("saveDataThread");
  }
}

String getEmailForCurrentUser() {
  // Retrieve the email for the current user from the database
  String userEmail = "";

  try {
    // Prepare the SELECT SQL statement to get the email
    String emailQuery = "SELECT email FROM SIGN WHERE id = ?";
    PreparedStatement pstmt = conn.prepareStatement(emailQuery);
    pstmt.setInt(1, id);

    // Execute the SELECT query
    ResultSet resultSet = pstmt.executeQuery();

    // Check if any row is returned
    if (resultSet.next()) {
      // Get the email from the result set
      userEmail = resultSet.getString("email");
    }

    // Close resources
    resultSet.close();
    pstmt.close();
  } catch (SQLException e) {
    e.printStackTrace();
    println("Error retrieving email for the current user");
  }

  return userEmail;
}
void saveDataThread() {
  // Set the flag to indicate that the saving thread is active
  savingThreadActive = true;

  // Perform the save data operations
  save_data.flush();
  save_data.close();
  calculateAveragesForCurrentUser();
  String message = calculateAveragesForCurrentUser();
  String targetUserId =  getEmailForCurrentUser();  
  String postData = "chat_id=" + targetUserId + "&text=" + message;

  sendPostRequest(apiUrl, postData);

  // Create a new save_data writer
  save_data = createWriter("sensordata.txt" + day() + "/" + month() + "/" + year() + ":" + hour() + "." + minute());

  // Reset the flag to indicate that the saving thread is no longer active
  savingThreadActive = false;
}

void sendRequest() {
  // Open a new client connection
  client = new processing.net.Client(this, esp32IP, esp32Port);
  if (client.active()) {
    // Send a request
    String request = "GET / HTTP/1.1\r\n" +
                     "Host: " + esp32IP + "\r\n\r\n";
    client.write(request);
  }
}

String calculateAveragesForCurrentUser() {
  // Calculate averages for the current user's ID and return a formatted string
  StringBuilder result = new StringBuilder();

  try {
    // Prepare the SELECT SQL statement to get the averages
    String avgQuery = "SELECT AVG(VATA) AS avgVATA, AVG(PIIA) AS avgPIIA, AVG(KAPHA) AS avgKAPHA FROM PULSE WHERE id = ?";
    PreparedStatement pstmt = conn.prepareStatement(avgQuery);
    pstmt.setInt(1, id);

    // Execute the SELECT query
    ResultSet resultSet = pstmt.executeQuery();

    // Check if any row is returned
    if (resultSet.next()) {
      // Get the average values from the result set
      float avgVATA = resultSet.getFloat("avgVATA");
      float avgPIIA = resultSet.getFloat("avgPIIA");
      float avgKAPHA = resultSet.getFloat("avgKAPHA");

      // Append the average values to the result string
      result.append("Average VATA: ").append(avgVATA).append("\n");
      result.append("Average PIIA: ").append(avgPIIA).append("\n");
      result.append("Average KAPHA: ").append(avgKAPHA).append("\n");
    }

    // Close resources
    resultSet.close();
    pstmt.close();
  } catch (SQLException e) {
    e.printStackTrace();
    println("Error calculating averages for the current user");
  }

  return result.toString();
}void stop() {
  // Close the client connection when the sketch is stopped
  if (client != null && client.active()) {
    client.stop();
  }
}

void sendPostRequest(String url, String data) {
  try {
    // Create a URL object
    URL apiUrl = new URL(url);

    // Open a connection
    HttpURLConnection connection = (HttpURLConnection) apiUrl.openConnection();

    // Set the request method to POST
    connection.setRequestMethod("POST");

    // Enable input/output streams
    connection.setDoOutput(true);

    // Set the content type
    connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");

    // Get the output stream
    try (DataOutputStream outputStream = new DataOutputStream(connection.getOutputStream())) {
      // Write the data
      outputStream.writeBytes(data);
      outputStream.flush();
    }

    // Get the response code (optional)
    int responseCode = connection.getResponseCode();
    println("Response Code: " + responseCode);

    // Close the connection
    connection.disconnect();
  } 
  catch (Exception e) {
    println("An error occurred: " + e.getMessage());
  }
}
