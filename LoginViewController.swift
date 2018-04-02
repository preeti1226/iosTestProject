

import UIKit
var userdt: userData!

class LoginViewController: UIViewController,UITextFieldDelegate{
    @IBOutlet var loginBtn: UIButton!
    @IBOutlet var userPasswordField: UITextField!
    @IBOutlet var userNameTextField: UITextField!
    
    var username:String="";
    var password:String="";
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
        username="";
        password="";
        userdt = userData()
        userNameTextField.layer.cornerRadius=20.0;
        userPasswordField.layer.cornerRadius=20.0;
        loginBtn.layer.cornerRadius=20.0;
        userNameTextField.delegate=self;
        userPasswordField.delegate=self;
        }
    
    
    @IBAction func loginBtnAction(_ sender: Any){
        username=userNameTextField.text!
        password=userPasswordField.text!
        var apiUrl :String = "http://comioispmobile.infield.co.in/ispmobile/Login?AppVersion=2.7"
        apiUrl.append("&username=" + username);
        apiUrl.append("&password=" + password);
        let userdata: userInfo = userInfo()
        let urlString = URL(string: apiUrl)
        if let url = urlString{
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) -> Void in
                if error != nil{
                    print(error.debugDescription)}
                else{
                do{
                    if let parseJSON = try JSONSerialization.jsonObject(with: data!) as? [String: Any]{
                        userdt.status = parseJSON["status"] as? Bool
                        if(userdt.status){
                            if let resultValue = parseJSON["data"] as? [NSDictionary]{
                                userdata.ISPName=resultValue[0]["ISPName"]as!String
                                userdata.EmployeeCode=resultValue[0]["EmployeeCode"]as! String
                                userdata.City=resultValue[0]["City"]as! String
                                userdata.CurrentStore=resultValue[0]["CurrentStore"]as!String
                                userdata.CounterCode=resultValue[0]["CounterCode"]as! String
                                userdata.Pmobile1=resultValue[0]["Pmobile1"]as! String
                                userdt.data.append(userdata)
                                
                                DispatchQueue.main.async {
                                 self.performSegue(withIdentifier: "HomeScreenSegue", sender:self)
                                 }
                            }
                        }else{
                            self.displayMessage(userMessage: "Please enter right username and password")
                            return;
                            }
                        
                        }
                    }catch{
                        print(error)}

                    }
                }
            task.resume()
        }
    }
    
     func textFieldShouldReturn(_ userNameTextField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      let destVC=segue.destination as! UserProfileViewController
       destVC.username=userNameTextField.text!
        
    }
    func displayMessage(userMessage:String)-> Void{
       DispatchQueue.main.async {
          let alertcontroller=UIAlertController(title:"Alert",message:userMessage,preferredStyle:.alert)
            let OkAction=UIAlertAction(title:"OK",style:.default)
            {(action:UIAlertAction!) in
                print("Ok button tapped");
                
            }
            alertcontroller.addAction(OkAction)
            self.present(alertcontroller,animated:true,completion:nil)
        }
    }
        
}

