import { initializeApp } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyA29ske8F-9mEwHRr-tAZniy3gD7iTW8Bw",
  authDomain: "neurohelp-95e92.firebaseapp.com",
  projectId: "neurohelp-95e92",
  storageBucket: "neurohelp-95e92.firebasestorage.app",
  messagingSenderId: "1082023733271",
  appId: "1:1082023733271:android:0578b6b7f47df2dd17d452"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
