
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Settings from '../pages/user/Settings'; 
import AddressManagementPage from '../pages/Addressmanagement';
import CurrencyPreferencesPage from '../pages/Currencypreference';

function Settingroute() {
  return (
    <Router>
      <Routes>
        <Route path="/settings" element={<Settings />} />
        <Route path="/address-management" element={<AddressManagementPage />} />
        <Route path="/currency-preferences" element={<CurrencyPreferencesPage />} />
        
        
      </Routes>
    </Router>
  );
}

export default Settingroute;