import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = 'Team 4';
  afuConfig = {
    formatsAllowed: ".csv",
    uploadAPI: {
      // url:"https://mkwlznhsr0.execute-api.us-east-1.amazonaws.com/dev/team-4-upload-bucket",
      url:"https://mkwlznhsr0.execute-api.us-east-1.amazonaws.com/dev/team4test",
      headers: {
        // 'Content-Type': 'multipart/form-data',
        'Access-Control-Allow-Origin': '*',
        //'Access-Control-Allow-Origin': 'http://team4test.s3-website-us-east-1.amazonaws.com',
        //'Access-Control-Allow-Origin': 'http://localhost:4200',
        'Access-Control-Allow-Headers': 'accept, content-type',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
      }
      // url:"https://vb9hx9u27j.execute-api.us-east-1.amazonaws.com/Team4Backend/team-4-upload-bucket" -- Shawn API
    }
};
}
