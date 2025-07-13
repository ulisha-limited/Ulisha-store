import React, { useState } from "react";
import {
    LayoutDashboardIcon,
    ShoppingCartIcon,
    User,
    Share,
    Settings,
} from "lucide-react";
import Menu from "./menu/Menu";

function Dropdown() {
    const [open, setOpen] = useState(false);

    return (
        <div className="relative inline-block text-left w-full ">
            <button
                onClick={() => setOpen((prev) => !prev)}
                className="inline-flex justify-between w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-blue-700 hover:text-white transition-all duration-300"
            >
                Menu
                <svg
                    className={`ml-2 h-5 w-5 transition-transform duration-300 ${open ? "rotate-180" : ""}`}
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                >
                    <path
                        fillRule="evenodd"
                        d="M5.23 7.21a.75.75 0 011.06.02L10 10.584l3.71-3.354a.75.75 0 111.02 1.1l-4.25 3.84a.75.75 0 01-1.02 0l-4.25-3.84a.75.75 0 01.02-1.06z"
                        clipRule="evenodd"
                    />
                </svg>
            </button>
            {open && (
                <div className="origin-top-left w-full absolute left-0 mt-2 w-64 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-50">
                    <div className="py-2 flex flex-col">
                        <Menu />
                    </div>
                </div>
            )}
        </div>
    );
}

export default Dropdown;
