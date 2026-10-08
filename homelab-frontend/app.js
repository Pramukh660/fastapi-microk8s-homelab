const API = (window.APP_CONFIG && window.APP_CONFIG.apiUrl) || "";
const $ = (id) => document.getElementById(id);
$("api").textContent = API;

async function call(path) {
  try {
    const res = await fetch(API + path);
    const data = await res.json();
    $("out").textContent = JSON.stringify(data, null, 2);
    return data;
  } catch (e) {
    $("out").textContent = "Error: " + e.message;
  }
}

$("rootBtn").onclick = () => call("/");
$("healthBtn").onclick = () => call("/health");

fetch(API + "/health")
  .then((r) => r.json())
  .then((d) => ($("status").textContent = d.status))
  .catch(() => ($("status").textContent = "unreachable"));
