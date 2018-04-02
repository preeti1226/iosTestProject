import UIKit

class UserProfileViewController: UIViewController

{
    @IBOutlet var getStartedBtn: UIButton!
    @IBOutlet var logOutBtn: UIButton!
    @IBOutlet var getUserName: UILabel!
    var username : String="";
    override func viewDidLoad() {
        super.viewDidLoad()
        getUserName.text=username;
        logOutBtn.layer.cornerRadius=6.0;

    }
    @IBAction func logoutBtn(_ sender: Any) {
        self.performSegue(withIdentifier: "loginPageSegue", sender:self);
    }
  
    @IBAction func userProfileAction(_ sender: Any) {
        self.performSegue(withIdentifier: "UserDataProfileSegue", sender: self)
    }
}
