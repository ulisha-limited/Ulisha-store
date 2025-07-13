import React from 'react'

function Page404() {

    return (
        <div className="bg-gray-100 min-h-screen flex flex-row items-center">
            <div className="container mx-auto">
                <div className="flex justify-center">
                    <div className="w-full max-w-xl">
                        <div className="mb-8">
                            <h1 className="float-left text-7xl font-bold mr-6">404</h1>
                            <h4 className="pt-3 text-xl font-semibold">Oops! You{"'"}re lost.</h4>
                            <p className="text-gray-500 float-left">
                                The page you are looking for was not found.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default React.memo(Page404);
