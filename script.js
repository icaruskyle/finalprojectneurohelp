import { db } from "./firebase.js";
import {
  collection,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  doc
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";

// ---------------- SIDEBAR NAVIGATION ----------------
document.querySelectorAll(".nav-item").forEach(item => {
  item.addEventListener("click", async () => {
    document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));
    document.getElementById(item.dataset.page).classList.add("active");

    document.querySelectorAll(".nav-item").forEach(li => li.classList.remove("active"));
    item.classList.add("active");

    switch(item.dataset.page){
      case "users": await loadUsers(); break;
      case "journal": await loadJournals(); break;
      case "mood": await loadMoods(); break;
      case "feedback": await loadFeedback(); break;
      case "articles": await loadArticles(); break;
      case "community": await loadCommunity(); break;
      case "events": await loadEvents(); break;
      case "dashboard": await loadDashboard(); break;
    }
  });
});

// ---------------- DARK MODE ----------------
const darkToggle = document.getElementById("darkModeToggle");
darkToggle.addEventListener("click", () => {
  document.body.classList.toggle("dark-mode");
  localStorage.setItem("darkMode", document.body.classList.contains("dark-mode"));
});
if(localStorage.getItem("darkMode") === "true") document.body.classList.add("dark-mode");

// ---------------- DASHBOARD ----------------
async function loadDashboard(filterDate = null) {
  const usersSnap = await getDocs(collection(db,"users"));
  const totalUsers = usersSnap.size;

  let totalJournals = 0;
  let totalMoods = 0;
  const moodCount = {};

  for (const userDoc of usersSnap.docs) {
    const uid = userDoc.id;

    const journalSnap = await getDocs(collection(db, `users/${uid}/daily_journal`));
    journalSnap.forEach(d => {
      const data = d.data();
      const journalDate = data.date || (data.createdAt ? new Date(data.createdAt.toDate()).toLocaleDateString() : null);
      if (!filterDate || journalDate === filterDate) totalJournals++;
    });

    const moodSnap = await getDocs(collection(db, `users/${uid}/mood_history`));
    moodSnap.forEach(d => {
      const moodData = d.data();
      const moodDate = moodData.date || (moodData.createdAt ? new Date(moodData.createdAt.toDate()).toLocaleDateString() : null);
      if (!filterDate || moodDate === filterDate) {
        totalMoods++;
        const mood = moodData.mood;
        moodCount[mood] = (moodCount[mood] || 0) + 1;
      }
    });
  }

  document.getElementById("totalUsers").innerText = totalUsers;
  document.getElementById("totalJournals").innerText = totalJournals;
  document.getElementById("totalMoods").innerText = totalMoods;

  const ctx = document.getElementById("moodChart").getContext("2d");
  new Chart(ctx, {
    type: "bar",
    data: {
      labels: Object.keys(moodCount),
      datasets: [{label:"Mood Count", data:Object.values(moodCount), backgroundColor:"#9b59ff"}]
    },
    options: { responsive:true, plugins:{legend:{display:false}} }
  });
}

// ---------------- DATE FILTER INPUT ----------------
const journalDateFilter = document.getElementById("journalDateFilter");
journalDateFilter.addEventListener("change", () => {
  const selectedDate = journalDateFilter.value;
  const formattedDate = new Date(selectedDate).toLocaleDateString();
  loadDashboard(formattedDate);
});

// ---------------- USERS ----------------
const userTable = document.getElementById("userTable");
async function loadUsers(){
  const searchValue = document.getElementById("userSearch").value.toLowerCase();
  const snapshot = await getDocs(collection(db,"users"));
  userTable.querySelector("tbody").innerHTML = "";
  snapshot.forEach(docSnap=>{
    const data = docSnap.data();
    if(searchValue && !(data.name?.toLowerCase().includes(searchValue) || data.email?.toLowerCase().includes(searchValue))) return;

    userTable.querySelector("tbody").innerHTML += `<tr>
      <td>${docSnap.id}</td>
      <td contenteditable="true" data-field="email" data-id="${docSnap.id}">${data.email||""}</td>
      <td contenteditable="true" data-field="name" data-id="${docSnap.id}">${data.name||""}</td>
      <td>
        <button onclick="deleteUser('${docSnap.id}')">Delete</button>
        <button onclick="saveUser('${docSnap.id}')">Save</button>
      </td>
    </tr>`;
  });
}

window.saveUser = async uid=>{
  const row = [...userTable.querySelectorAll(`td[data-id='${uid}']`)];
  const email = row.find(td=>td.dataset.field==="email").innerText;
  const name = row.find(td=>td.dataset.field==="name").innerText;
  await updateDoc(doc(db,"users",uid), {email,name});
  alert("User updated!");
}

window.deleteUser = async uid=>{
  if(confirm("Delete user?")){
    await deleteDoc(doc(db,"users",uid));
    loadUsers();
  }
}

document.getElementById("userSearch").addEventListener("input", loadUsers);

// ---------------- SELECT USER IDS ----------------
const selectUserIdJournal = document.getElementById("selectUserIdJournal");
const selectUserIdMood = document.getElementById("selectUserIdMood");
const selectUserIdFeedback = document.getElementById("selectUserIdFeedback");

async function loadUserDropdowns() {
  const usersSnap = await getDocs(collection(db,"users"));
  const allSelects = [selectUserIdJournal, selectUserIdMood, selectUserIdFeedback];

  allSelects.forEach(select => select.innerHTML = '<option value="">-- Select User ID --</option>');

  usersSnap.forEach(userDoc => {
    const uid = userDoc.id;
    allSelects.forEach(select => {
      select.innerHTML += `<option value="${uid}">${uid}</option>`;
    });
  });
}

// ---------------- JOURNALS ----------------
const journalTable = document.getElementById("journalTable");
const journalSearch = document.getElementById("journalSearch");

async function loadJournals() {
  const uid = selectUserIdJournal.value;
  if (!uid) {
    journalTable.querySelector("tbody").innerHTML = `<tr><td colspan="4">Please select a user first</td></tr>`;
    return;
  }

  const searchValue = journalSearch.value.toLowerCase();
  const dateFilter = journalDateFilter.value;
  const journalSnap = await getDocs(collection(db, `users/${uid}/daily_journal`));
  journalTable.querySelector("tbody").innerHTML = "";

  journalSnap.forEach(d => {
    const data = d.data();
    const predictedMood = data.mood || "[No Mood]";
    const entryDate = data.date ? new Date(data.date).toISOString().split("T")[0] : "";

    if ((searchValue && !predictedMood.toLowerCase().includes(searchValue)) ||
        (dateFilter && entryDate !== dateFilter)) return;

    journalTable.querySelector("tbody").innerHTML += `<tr>
      <td>${uid}</td>
      <td contenteditable="true" data-field="mood" data-id="${d.id}" data-user="${uid}">${predictedMood}</td>
      <td>${entryDate}</td>
      <td>
        <button onclick="deleteJournal('${uid}','${d.id}')">Delete</button>
        <button onclick="saveJournal('${uid}','${d.id}')">Save</button>
      </td>
    </tr>`;
  });
}

window.saveJournal = async (uid, id) => {
  const row = [...journalTable.querySelectorAll(`td[data-id='${id}'][data-user='${uid}']`)];
  const mood = row.find(td => td.dataset.field === "mood").innerText;
  await updateDoc(doc(db, `users/${uid}/daily_journal`, id), { mood });
  alert("Journal updated!");
}

window.deleteJournal = async (uid, id) => {
  if (confirm("Delete journal?")) {
    await deleteDoc(doc(db, `users/${uid}/daily_journal`, id));
    loadJournals();
  }
}

journalSearch.addEventListener("input", loadJournals);
journalDateFilter.addEventListener("change", loadJournals);
selectUserIdJournal.addEventListener("change", loadJournals);

// ---------------- MOODS ----------------
const moodTable = document.getElementById("moodTable");
const moodFilter = document.getElementById("moodFilter");

const positiveMoods = ["😊 Happy","😇 Grateful","😌 Content","😎 Confident","🥳 Excited","😚 Loved","🤗 Hopeful","🤩 Inspired","😋 Playful","🤠 Cheerful","🧘 Calm","🙂 Neutral"];
const negativeMoods = ["😢 Sad","💔 Heartbroken","😞 Disappointed","😔 Lonely","😩 Overwhelmed","😕 Confused","😟 Anxious","😰 Stressed","😤 Frustrated","😠 Irritated","😡 Angry","😬 Nervous","😳 Embarrassed","😴 Tired","😫 Exhausted","😩 Hopeless","😶 Empty","😑 Bored","🤒 Unwell","🤯 Burned Out","⚠️ Suicidal/Warning"];
const neutralMoods = ["🤔 Reflective","😌 Thoughtful","😮 Surprised","😶 Indifferent","😐 Blank","🫤 Uncertain","🤫 Quiet","😅 Awkward","🤨 Skeptical","🤓 Focused","🤭 Amused"];

async function loadMoods() {
  const uid = selectUserIdMood.value;
  if (!uid) {
    moodTable.querySelector("tbody").innerHTML = `<tr><td colspan="3">Please select a user first</td></tr>`;
    return;
  }

  const selectedFilter = moodFilter.value;
  const moodSnap = await getDocs(collection(db, `users/${uid}/mood_history`));
  moodTable.querySelector("tbody").innerHTML = "";

  moodSnap.forEach(d => {
    const data = d.data();
    const mood = data.mood || "[No Mood]";
    const entryDate = data.date ? new Date(data.date).toLocaleString() : "-";

    if (selectedFilter === "positive" && !positiveMoods.includes(mood)) return;
    if (selectedFilter === "negative" && !negativeMoods.includes(mood)) return;
    if (selectedFilter === "neutral" && !neutralMoods.includes(mood)) return;

    moodTable.querySelector("tbody").innerHTML += `<tr>
      <td>${uid}</td>
      <td>${mood}</td>
      <td>${entryDate}</td>
    </tr>`;
  });
}

selectUserIdMood.addEventListener("change", loadMoods);
moodFilter.addEventListener("change", loadMoods);

// ---------------- FEEDBACK ----------------
const feedbackTable = document.getElementById("feedbackTable");

async function loadFeedback() {
  const uid = selectUserIdFeedback.value;
  if (!uid) {
    feedbackTable.querySelector("tbody").innerHTML = `<tr><td colspan="4">Please select a user first</td></tr>`;
    return;
  }

  try {
    const fbSnap = await getDocs(collection(db, `users/${uid}/feedback`));
    const tbody = feedbackTable.querySelector("tbody");
    tbody.innerHTML = "";

    if (fbSnap.empty) {
      tbody.innerHTML = `<tr><td colspan="4">No feedback available for this user</td></tr>`;
      return;
    }

    fbSnap.forEach(docSnap => {
      const data = docSnap.data();
      let date = "-";
      if (data.timestamp) date = data.timestamp.toDate ? data.timestamp.toDate().toLocaleString() : new Date(data.timestamp).toLocaleString();

      tbody.innerHTML += `<tr>
        <td>${uid}</td>
        <td>${data.feedback || ""}</td>
        <td>${date}</td>
        <td><button onclick="deleteFeedback('${uid}','${docSnap.id}')">Delete</button></td>
      </tr>`;
    });
  } catch (error) {
    feedbackTable.querySelector("tbody").innerHTML = `<tr><td colspan="4">Error loading data</td></tr>`;
  }
}

selectUserIdFeedback.addEventListener("change", loadFeedback);

window.deleteFeedback = async (uid, id) => {
  if (confirm("Delete feedback?")) {
    await deleteDoc(doc(db, `users/${uid}/feedback`, id));
    loadFeedback();
  }
};

// ---------------- ARTICLES ----------------
const articleTable = document.getElementById("articleTable");

document.getElementById("addArticleBtn").addEventListener("click", async () => {
  const title = document.getElementById("articleTitle").value;
  const image = document.getElementById("articleImage").value;
  const content = document.getElementById("articleContent").value;

  if(title && content){
    await addDoc(collection(db,"articles"), {title,image,content,date:new Date().toISOString()});
    loadArticles();
  }
});

async function loadArticles(){
  const snapshot = await getDocs(collection(db,"articles"));
  articleTable.querySelector("tbody").innerHTML = "";

  snapshot.forEach(d=>{
    const data = d.data();
    articleTable.querySelector("tbody").innerHTML += `
      <tr>
        <td contenteditable="true" data-field="title" data-id="${d.id}">${data.title}</td>
        <td contenteditable="true" data-field="image" data-id="${d.id}">${data.image||""}</td>
        <td contenteditable="true" data-field="content" data-id="${d.id}">${data.content}</td>
        <td>${data.date}</td>
        <td>
          <button onclick="deleteArticle('${d.id}')">Delete</button>
          <button onclick="saveArticle('${d.id}')">Save</button>
        </td>
      </tr>`;
  });
}

window.saveArticle = async (id) => {
  const row = [...articleTable.querySelectorAll(`td[data-id='${id}']`)];
  const title = row.find(td=>td.dataset.field==="title").innerText;
  const image = row.find(td=>td.dataset.field==="image").innerText;
  const content = row.find(td=>td.dataset.field==="content").innerText;

  await updateDoc(doc(db,"articles",id),{title,image,content});
  alert("Article updated!");
};

window.deleteArticle = async (id) => {
  if(confirm("Delete this article?")){
    await deleteDoc(doc(db,"articles",id));
    loadArticles();
  }
};

// ---------------- COMMUNITY ----------------
const communityTable = document.getElementById("communityTable");

document.getElementById("addCommunityBtn").addEventListener("click", async () => {
  const title = document.getElementById("communityTitle").value;
  const message = document.getElementById("communityMessage").value;

  if(title && message){
    await addDoc(collection(db,"community"),{title,message,date:new Date().toISOString()});
    loadCommunity();
  }
});

async function loadCommunity(){
  const snapshot = await getDocs(collection(db,"community"));
  communityTable.querySelector("tbody").innerHTML = "";

  snapshot.forEach(d=>{
    const data = d.data();
    communityTable.querySelector("tbody").innerHTML += `
      <tr>
        <td contenteditable="true" data-field="title" data-id="${d.id}">${data.title}</td>
        <td contenteditable="true" data-field="message" data-id="${d.id}">${data.message}</td>
        <td>${data.date}</td>
        <td>
          <button onclick="deleteCommunity('${d.id}')">Delete</button>
          <button onclick="saveCommunity('${d.id}')">Save</button>
        </td>
      </tr>`;
  });
}

window.saveCommunity = async (id) => {
  const row = [...communityTable.querySelectorAll(`td[data-id='${id}']`)];
  const title = row.find(td=>td.dataset.field==="title").innerText;
  const message = row.find(td=>td.dataset.field==="message").innerText;

  await updateDoc(doc(db,"community",id),{title,message});
  alert("Community post updated!");
};

window.deleteCommunity = async (id) => {
  if(confirm("Delete this post?")){
    await deleteDoc(doc(db,"community",id));
    loadCommunity();
  }
};

// ---------------- EVENTS ----------------
const eventTable = document.getElementById("eventTable");

document.getElementById("addEventBtn").addEventListener("click", async () => {
  const eventTitle = document.getElementById("eventTitle").value;
  const eventDesc = document.getElementById("eventDescription").value;
  const eventDate = document.getElementById("eventDate").value;

  if (eventTitle && eventDesc && eventDate) {
    await addDoc(collection(db, "events"), {
      title: eventTitle,
      description: eventDesc,
      date: eventDate,
      createdAt: new Date().toISOString(),
    });
    loadEvents();
  }
});

async function loadEvents() {
  const snapshot = await getDocs(collection(db, "events"));
  eventTable.querySelector("tbody").innerHTML = "";

  snapshot.forEach((d) => {
    const data = d.data();
    eventTable.querySelector("tbody").innerHTML += `
      <tr>
        <td contenteditable="true" data-field="title" data-id="${d.id}">${data.title}</td>
        <td contenteditable="true" data-field="description" data-id="${d.id}">${data.description}</td>
        <td contenteditable="true" data-field="date" data-id="${d.id}">${data.date}</td>
        <td>
          <button onclick="deleteEvent('${d.id}')">Delete</button>
          <button onclick="saveEvent('${d.id}')">Save</button>
        </td>
      </tr>
    `;
  });
}

window.saveEvent = async (id) => {
  const row = [...eventTable.querySelectorAll(`td[data-id='${id}']`)];
  const title = row.find(td => td.dataset.field === "title").innerText;
  const description = row.find(td => td.dataset.field === "description").innerText;
  const date = row.find(td => td.dataset.field === "date").innerText;

  await updateDoc(doc(db, "events", id), { title, description, date });
  alert("Event updated!");
};

window.deleteEvent = async (id) => {
  if (confirm("Delete this event?")) {
    await deleteDoc(doc(db, "events", id));
    loadEvents();
  }
};

// ---------------- INITIAL LOAD ----------------
loadDashboard();
loadUsers();
loadUserDropdowns();
loadJournals();
loadMoods();
loadFeedback();
loadArticles();
loadCommunity();
loadEvents();
