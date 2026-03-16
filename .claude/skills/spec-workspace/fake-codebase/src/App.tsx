import { BrowserRouter, Routes, Route } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Sidebar } from "./components/Sidebar/Sidebar";
import { TaskBoard } from "./components/TaskBoard/TaskBoard";
import { Settings } from "./pages/Settings";
import { AuthProvider } from "./hooks/useAuth";

const queryClient = new QueryClient();

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <div className="app-layout">
            <Sidebar />
            <main>
              <Routes>
                <Route path="/board/:boardId" element={<TaskBoard />} />
                <Route path="/settings" element={<Settings />} />
              </Routes>
            </main>
          </div>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}
