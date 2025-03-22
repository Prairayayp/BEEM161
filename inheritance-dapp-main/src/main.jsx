import React from "react";
import ReactDOM from "react-dom/client";
import InheritanceDApp from "./InheritanceDApp"; // 👈 确保有 default export

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <InheritanceDApp />
  </React.StrictMode>
);
