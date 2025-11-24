import { db } from "./firebase.js";
import {
  collection,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  doc
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";

// ---------------- NAVIGATION ----------------
document.querySelectorAll(".nav-item").forEach(item => {
  item.addEventListener("click", () => {
    document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));
    document.getElementById(item.dataset.page).classList.add("active");
    document.querySelectorAll(".nav-item").forEach(li => li.classList.remove("active"));
    item.classList.add("active");

    switch(item.dataset.page){
      case "users": loadUsers(); break;
      case "journal": loadJournals(); break;
      case "mood": loadMoods(); break;
      case "feedback": loadFeedback(); break;
      case "content": loadContent(); break;
      case "notifications": loadNotifications(); break;
      case "logs": loadLogs(); break;
      case "dashboard": loadDashboard(); break;
    }
  });
});

// ---------------- DASHBOARD ----------------
async function loadDashboard(){
  const usersSnap = await getDocs(collection(db,"users"));
  const totalUsers = usersSnap.size;

  let totalJournals = 0, totalMoods = 0;

  for (const docSnap of usersSnap.docs){
    const uid = docSnap.id;

    const journalSnap = await getDocs(collection(db,"users",uid,"daily_journal"));
    const moodSnap = await getDocs(collection(db,"users",uid,"mood_history"));
    totalJournals += journalSnap.size;
    totalMoods += moodSnap.size;
  }

  document.getElementById("totalUsers").innerText = totalUsers;
  document.getElementById("totalJournals").innerText = totalJournals;
  document.getElementById("totalMoods").innerText = totalMoods;

  // Mood chart
  const moodCount = {};
  for (const docSnap of usersSnap.docs){
    const uid = docSnap.id;
    const moodSnap = await getDocs(collection(db,"users",uid,"mood_history"));
    moodSnap.forEach(moodDoc=>{
      const mood = moodDoc.data().mood;
      moodCount[mood] = (moodCount[mood]||0)+1;
    });
  }

  const ctx = document.getElementById("moodChart").getContext("2d");
  new Chart(ctx,{
    type:"bar",
    data:{
      labels:Object.keys(moodCount),
      datasets:[{label:"Mood Count",data:Object.values(moodCount),backgroundColor:"#9b59ff"}]
    },
    options:{responsive:true,plugins:{legend:{display:false}}}
  });
}

// ---------------- USERS ----------------
const userTable = document.getElementById("userTable");
async function loadUsers(){
  const snapshot = await getDocs(collection(db,"users"));
  userTable.innerHTML = "";
  snapshot.forEach(docSnap => {
    const uid = docSnap.id;
    const subcollections = ["breathing_sessions","chat_history","daily_journal","feedback","gratitude","mindfulness_sessions","mood_history"];
    userTable.innerHTML += `<tr>
      <td>${uid}</td>
      <td>${subcollections.join(", ")}</td>
    </tr>`;
  });
}

// ---------------- JOURNALS ----------------
const journalTable = document.getElementById("journalTable");
async function loadJournals(){
  const snapshot = await getDocs(collection(db,"users"));
  journalTable.innerHTML = "";

  for(const userDoc of snapshot.docs){
    const uid = userDoc.id;
    const journalSnap = await getDocs(collection(db,"users",uid,"daily_journal"));
    journalSnap.forEach(docSnap=>{
      const data = docSnap.data();
      journalTable.innerHTML += `<tr>
        <td>${uid}</td>
        <td contenteditable="true" data-field="entry" data-uid="${uid}" data-id="${docSnap.id}">${data.entry || ""}</td>
        <td>${data.date || ""}</td>
        <td>
          <button onclick="deleteJournal('${uid}','${docSnap.id}')">Delete</button>
          <button onclick="saveJournal('${uid}','${docSnap.id}')">Save</button>
        </td>
      </tr>`;
    });
  }
}

window.saveJournal = async (uid, id)=>{
  const row = [...journalTable.querySelectorAll(`td[data-id='${id}'][data-uid='${uid}']`)];
  const entry = row.find(td=>td.dataset.field==="entry").innerText;
  await updateDoc(doc(db,"users",uid,"daily_journal",id), {entry});
  alert("Journal updated!");
}

window.deleteJournal = async (uid,id)=>{
  if(confirm("Delete journal?")){
    await deleteDoc(doc(db,"users",uid,"daily_journal",id));
    loadJournals();
  }
}

// ---------------- MOODS ----------------
const moodTable = document.getElementById("moodTable");
async function loadMoods(){
  const snapshot = await getDocs(collection(db,"users"));
  moodTable.innerHTML = "";

  for(const userDoc of snapshot.docs){
    const uid = userDoc.id;
    const moodSnap = await getDocs(collection(db,"users",uid,"mood_history"));
    moodSnap.forEach(docSnap=>{
      const data = docSnap.data();
      moodTable.innerHTML += `<tr>
        <td>${uid}</td>
        <td>${data.mood || ""}</td>
        <td>${data.date || ""}</td>
      </tr>`;
    });
  }
}

// ---------------- FEEDBACK ----------------
const feedbackTable = document.getElementById("feedbackTable");
async function loadFeedback(){
  const snapshot = await getDocs(collection(db,"users"));
  feedbackTable.innerHTML = "";

  for(const userDoc of snapshot.docs){
    const uid = userDoc.id;
    const feedbackSnap = await getDocs(collection(db,"users",uid,"feedback"));
    feedbackSnap.forEach(docSnap=>{
      const data = docSnap.data();
      feedbackTable.innerHTML += `<tr>
        <td>${uid}</td>
        <td>${data.message || ""}</td>
        <td>${data.date || ""}</td>
        <td><button onclick="deleteFeedback('${uid}','${docSnap.id}')">Delete</button></td>
      </tr>`;
    });
  }
}

window.deleteFeedback = async (uid,id)=>{
  if(confirm("Delete feedback?")){
    await deleteDoc(doc(db,"users",uid,"feedback",id));
    loadFeedback();
  }
}

// ---------------- CONTENT ----------------
const contentTable = document.getElementById("contentTable");
document.getElementById("addContentBtn").addEventListener("click", async ()=>{
  const title = document.getElementById("contentTitle").value;
  const body = document.getElementById("contentBody").value;
  if(title && body){
    await addDoc(collection(db,"content"), {title,body,date:new Date().toISOString()});
    loadContent();
  }
});

async function loadContent(){
  const snapshot = await getDocs(collection(db,"content"));
  contentTable.innerHTML = "";
  snapshot.forEach(docSnap=>{
    const data = docSnap.data();
    contentTable.innerHTML += `<tr>
      <td contenteditable="true" data-field="title" data-id="${docSnap.id}">${data.title || ""}</td>
      <td contenteditable="true" data-field="body" data-id="${docSnap.id}">${data.body || ""}</td>
      <td>${data.date || ""}</td>
      <td>
        <button onclick="deleteContent('${docSnap.id}')">Delete</button>
        <button onclick="saveContent('${docSnap.id}')">Save</button>
      </td>
    </tr>`;
  });
}

window.saveContent = async (id)=>{
  const row = [...contentTable.querySelectorAll(`td[data-id='${id}']`)];
  const title = row.find(td=>td.dataset.field==="title").innerText;
  const body = row.find(td=>td.dataset.field==="body").innerText;
  await updateDoc(doc(db,"content",id), {title,body});
  alert("Content updated!");
}

window.deleteContent = async (id)=>{
  if(confirm("Delete content?")){
    await deleteDoc(doc(db,"content",id));
    loadContent();
  }
}

// ---------------- NOTIFICATIONS ----------------
document.getElementById("sendNotificationBtn").addEventListener("click", async ()=>{
  const message = document.getElementById("notificationMessage").value;
  if(message){
    await addDoc(collection(db,"notifications"), {message,date:new Date().toISOString()});
    loadNotifications();
  }
});

async function loadNotifications(){
  const snapshot = await getDocs(collection(db,"notifications"));
  const table = document.getElementById("notificationsTable");
  table.innerHTML = "";
  snapshot.forEach(docSnap=>{
    const data = docSnap.data();
    table.innerHTML += `<tr><td>${data.message}</td><td>${data.date}</td></tr>`;
  });
}

// ---------------- SYSTEM LOGS ----------------
async function loadLogs(){
  const snapshot = await getDocs(collection(db,"system_logs"));
  const table = document.getElementById("logsTable");
  table.innerHTML = "";
  snapshot.forEach(docSnap=>{
    const data = docSnap.data();
    table.innerHTML += `<tr>
      <td>${data.action || ""}</td>
      <td>${data.adminUid || ""}</td>
      <td>${data.date || ""}</td>
    </tr>`;
  });
}

// ---------------- INITIAL LOAD ----------------
loadDashboard();
loadUsers();
loadJournals();
loadMoods();
loadFeedback();
loadContent();
loadNotifications();
loadLogs();
